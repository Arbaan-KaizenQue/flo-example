import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../models/backup_snapshot.dart';
import '../models/cycle_log.dart';
import '../models/json_response.dart';
import '../models/mood_entry.dart';
import '../models/note.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';
import '../models/weight_log.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import 'cycle_log_repository.dart';
import 'mood_repository.dart';
import 'note_repository.dart';
import 'onboarding_repository.dart';
import 'sleep_repository.dart';
import 'symptom_repository.dart';
import 'water_repository.dart';
import 'weight_repository.dart';

/// [DriveRepository] — full pull → per-collection LWW merge → push.
/// Every entity collection round-trips through Drive (Feature: Full Sync).
abstract class DriveRepository {
  Future<JsonResponse> performSync();
  Future<JsonResponse> deleteCloudBackup();

  /// Pull-only — used by Welcome sign-in path to detect "do I have a backup?"
  /// Returns `data: BackupSnapshot?` (null if no file in Drive).
  Future<JsonResponse> pullRemoteSnapshot();

  /// Welcome sign-in flow: enable Drive, sync, report whether any data
  /// was restored to local. `data: bool` — true if local now has content.
  Future<JsonResponse> restoreOnSignIn();

  DateTime? get lastSyncedAt;
  bool get driveEnabled;
  bool get isSignedIn;
}

class DriveRepositoryImpl implements DriveRepository {
  DriveRepositoryImpl({
    required this.driveService,
    required this.authService,
    required this.prefs,
    required this.cycleLogRepo,
    required this.symptomRepo,
    required this.waterRepo,
    required this.sleepRepo,
    required this.weightRepo,
    required this.noteRepo,
    required this.moodRepo,
    required this.onboardingRepo,
  });

  final DriveService driveService;
  final AuthService authService;
  final SharedPreferences prefs;
  final CycleLogRepository cycleLogRepo;
  final SymptomRepository symptomRepo;
  final WaterRepository waterRepo;
  final SleepRepository sleepRepo;
  final WeightRepository weightRepo;
  final NoteRepository noteRepo;
  final MoodRepository moodRepo;
  final OnboardingRepository onboardingRepo;

  Completer<void>? _activeSync;

  @override
  bool get driveEnabled =>
      prefs.getBool(StorageKeys.driveSyncEnabled) ?? false;

  @override
  bool get isSignedIn => authService.currentUser != null;

  @override
  DateTime? get lastSyncedAt {
    final raw = prefs.getString(StorageKeys.lastSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  // ============================================================
  // Pure LWW merge (last-write-wins on updatedAt; local wins ties)
  // ============================================================

  static List<T> _mergeBy<T>({
    required List<T> local,
    required List<T> remote,
    required String Function(T) id,
    required DateTime Function(T) updatedAt,
  }) {
    final map = <String, T>{};
    for (final i in local) {
      map[id(i)] = i;
    }
    for (final r in remote) {
      final key = id(r);
      final existing = map[key];
      if (existing == null) {
        map[key] = r;
      } else if (updatedAt(r).isAfter(updatedAt(existing))) {
        map[key] = r;
      }
    }
    return map.values.toList(growable: false);
  }

  // ============================================================
  // Public API
  // ============================================================

  @override
  Future<JsonResponse> pullRemoteSnapshot() async {
    if (!isSignedIn) {
      return JsonResponse.failure(
        message: 'Not signed in',
        statusCode: 401,
      );
    }
    try {
      final findRes = await driveService.findBackupFileId();
      if (!findRes.success) return findRes;
      final fileId = findRes.data as String?;
      if (fileId == null) {
        return JsonResponse.success(message: 'No backup found', data: null);
      }
      final pullRes = await driveService.pullBackup(fileId);
      if (!pullRes.success) return pullRes;
      return JsonResponse.success(
        message: 'Pulled',
        data: pullRes.data as BackupSnapshot,
      );
    } catch (e) {
      return JsonResponse.failure(message: 'Pull failed: $e');
    }
  }

  @override
  Future<JsonResponse> performSync() async {
    if (!driveEnabled || !isSignedIn) {
      return JsonResponse.failure(
        message: 'Drive disabled or not signed in',
        statusCode: 412,
      );
    }
    if (_activeSync != null) {
      await _activeSync!.future;
      return JsonResponse.success(message: 'Already syncing');
    }
    _activeSync = Completer<void>();
    try {
      // 1) PULL
      final findRes = await driveService.findBackupFileId();
      if (!findRes.success) return findRes;
      final remoteFileId = findRes.data as String?;
      BackupSnapshot remote;
      if (remoteFileId == null) {
        remote = BackupSnapshot.empty();
      } else {
        final pullRes = await driveService.pullBackup(remoteFileId);
        if (!pullRes.success) return pullRes;
        remote = pullRes.data as BackupSnapshot;
      }

      // 2) READ LOCAL (incl deleted) from every repo
      final localCycles = cycleLogRepo.getAllIncludingDeleted();
      final localSymptoms = symptomRepo.getAllIncludingDeleted();
      final localWater = waterRepo.getAllIncludingDeleted();
      final localSleep = sleepRepo.getAllIncludingDeleted();
      final localWeight = weightRepo.getAllIncludingDeleted();
      final localNotes = noteRepo.getAllIncludingDeleted();
      final localMood = moodRepo.getAllIncludingDeleted();
      final localOnboarding = onboardingRepo.loadAnswers();

      // 3) MERGE per-collection (LWW)
      final mergedCycles = _mergeBy<CycleLog>(
        local: localCycles,
        remote: remote.cycleLogs,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedSymptoms = _mergeBy<SymptomEntry>(
        local: localSymptoms,
        remote: remote.symptoms,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedWater = _mergeBy<WaterLog>(
        local: localWater,
        remote: remote.water,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedSleep = _mergeBy<SleepLog>(
        local: localSleep,
        remote: remote.sleep,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedWeight = _mergeBy<WeightLog>(
        local: localWeight,
        remote: remote.weight,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedNotes = _mergeBy<Note>(
        local: localNotes,
        remote: remote.notes,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      final mergedMood = _mergeBy<MoodEntry>(
        local: localMood,
        remote: remote.mood,
        id: (e) => e.id,
        updatedAt: (e) => e.updatedAt,
      );
      // Onboarding: single record. Take remote only if local is empty
      // (heuristic — onboarding answers don't have an updatedAt today).
      final mergedOnboarding = localOnboarding.ageGroup.isEmpty &&
              remote.onboardingAnswers != null
          ? remote.onboardingAnswers
          : localOnboarding;

      // 4) WRITE merged back to local (replaces every box atomically)
      await cycleLogRepo.replaceAll(mergedCycles);
      await symptomRepo.replaceAll(mergedSymptoms);
      await waterRepo.replaceAll(mergedWater);
      await sleepRepo.replaceAll(mergedSleep);
      await weightRepo.replaceAll(mergedWeight);
      await noteRepo.replaceAll(mergedNotes);
      await moodRepo.replaceAll(mergedMood);
      if (mergedOnboarding != null) {
        await onboardingRepo.saveAnswers(mergedOnboarding);
      }

      // 5) PUSH merged snapshot
      final now = DateTime.now().toUtc();
      final newSnapshot = BackupSnapshot(
        version: AppConstants.backupSnapshotVersion,
        lastSyncedAt: now,
        cycleLogs: mergedCycles,
        symptoms: mergedSymptoms,
        water: mergedWater,
        sleep: mergedSleep,
        weight: mergedWeight,
        notes: mergedNotes,
        mood: mergedMood,
        onboardingAnswers: mergedOnboarding,
      );
      final pushRes = await driveService.pushBackup(
        newSnapshot,
        existingFileId: remoteFileId,
      );
      if (!pushRes.success) return pushRes;

      await prefs.setString(
        StorageKeys.lastSyncedAt,
        now.toIso8601String(),
      );
      return JsonResponse.success(message: 'Synced', data: now);
    } catch (e) {
      return JsonResponse.failure(message: 'Sync failed: $e');
    } finally {
      _activeSync!.complete();
      _activeSync = null;
    }
  }

  @override
  Future<JsonResponse> restoreOnSignIn() async {
    if (!isSignedIn) {
      return JsonResponse.failure(
        message: 'Not signed in',
        statusCode: 401,
      );
    }
    // Force-enable Drive so performSync proceeds.
    await prefs.setBool(StorageKeys.driveSyncEnabled, true);
    final syncRes = await performSync();
    if (!syncRes.success) return syncRes;

    final hasData = cycleLogRepo.getAllIncludingDeleted().isNotEmpty ||
        symptomRepo.getAllIncludingDeleted().isNotEmpty ||
        waterRepo.getAllIncludingDeleted().isNotEmpty ||
        sleepRepo.getAllIncludingDeleted().isNotEmpty ||
        weightRepo.getAllIncludingDeleted().isNotEmpty ||
        noteRepo.getAllIncludingDeleted().isNotEmpty ||
        moodRepo.getAllIncludingDeleted().isNotEmpty ||
        onboardingRepo.loadAnswers().ageGroup.isNotEmpty;
    return JsonResponse.success(
      message: hasData ? 'Backup restored' : 'No backup found',
      data: hasData,
    );
  }

  @override
  Future<JsonResponse> deleteCloudBackup() async {
    try {
      final findRes = await driveService.findBackupFileId();
      if (!findRes.success) return findRes;
      final id = findRes.data as String?;
      if (id != null) {
        final del = await driveService.deleteBackup(id);
        if (!del.success) return del;
      }
      await prefs.remove(StorageKeys.lastSyncedAt);
      return JsonResponse.success(message: 'Cloud backup deleted');
    } catch (e) {
      return JsonResponse.failure(message: 'Delete failed: $e');
    }
  }
}
