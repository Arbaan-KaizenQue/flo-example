import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../models/backup_snapshot.dart';
import '../models/json_response.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';

/// [DriveRepository] — pulls + pushes the backup snapshot file.
/// Feature data will be added to [BackupSnapshot] in Feature 14 / 16; for
/// now this just exercises the round-trip so the plumbing stays warm.
abstract class DriveRepository {
  Future<JsonResponse> performSync();
  Future<JsonResponse> deleteCloudBackup();
  DateTime? get lastSyncedAt;
  bool get driveEnabled;
  bool get isSignedIn;
}

class DriveRepositoryImpl implements DriveRepository {
  DriveRepositoryImpl({
    required this.driveService,
    required this.authService,
    required this.prefs,
  });

  final DriveService driveService;
  final AuthService authService;
  final SharedPreferences prefs;

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
      final findRes = await driveService.findBackupFileId();
      if (!findRes.success) return findRes;
      final remoteFileId = findRes.data as String?;

      // For now, pulling just confirms the file exists / is well-formed.
      if (remoteFileId != null) {
        final pullRes = await driveService.pullBackup(remoteFileId);
        if (!pullRes.success) return pullRes;
      }

      final now = DateTime.now().toUtc();
      final snapshot = BackupSnapshot(
        version: AppConstants.backupSnapshotVersion,
        lastSyncedAt: now,
      );
      final pushRes = await driveService.pushBackup(
        snapshot,
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
