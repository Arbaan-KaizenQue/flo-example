import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/storage_keys.dart';
import '../models/backup_snapshot.dart';
import '../models/item.dart';
import '../models/json_response.dart';
import '../services/auth_service.dart';
import '../services/drive_service.dart';
import 'item_repository.dart';

/// [DriveRepository] — orchestrates the full pull-merge-push sync flow.
/// Last-write-wins on `updatedAt`; local wins on identical timestamps.
abstract class DriveRepository {
  Future<JsonResponse> performSync();
  Future<JsonResponse> pushOnlyIfPending();
  Future<JsonResponse> deleteCloudBackup();
  DateTime? get lastSyncedAt;
  bool get driveEnabled;
  bool get isSignedIn;
}

class DriveRepositoryImpl implements DriveRepository {
  DriveRepositoryImpl({
    required this.driveService,
    required this.authService,
    required this.itemRepository,
    required this.prefs,
  });

  final DriveService driveService;
  final AuthService authService;
  final ItemRepository itemRepository;
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

  /// Pure LWW merge keyed by [Item.id]. Local wins on timestamp ties.
  static List<Item> merge(List<Item> local, List<Item> remote) {
    final map = <String, Item>{};
    for (final i in local) {
      map[i.id] = i;
    }
    for (final r in remote) {
      final existing = map[r.id];
      if (existing == null) {
        map[r.id] = r;
        continue;
      }
      if (r.updatedAt.isAfter(existing.updatedAt)) {
        map[r.id] = r;
      }
      // else: keep local (already in map)
    }
    return map.values.toList(growable: false);
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

      BackupSnapshot remoteSnapshot;
      if (remoteFileId == null) {
        remoteSnapshot = BackupSnapshot.empty();
      } else {
        final pullRes = await driveService.pullBackup(remoteFileId);
        if (!pullRes.success) return pullRes;
        remoteSnapshot = pullRes.data as BackupSnapshot;
      }

      final localRes = await itemRepository.getAllIncludingDeleted();
      if (!localRes.success) return localRes;
      final localItems = localRes.data as List<Item>;

      final merged = merge(localItems, remoteSnapshot.items);

      final replaceRes = await itemRepository.replaceAll(merged);
      if (!replaceRes.success) return replaceRes;

      final now = DateTime.now().toUtc();
      final newSnapshot = BackupSnapshot(
        version: AppConstants.backupSnapshotVersion,
        lastSyncedAt: now,
        items: merged,
      );
      final pushRes = await driveService.pushBackup(
        newSnapshot,
        existingFileId: remoteFileId,
      );
      if (!pushRes.success) return pushRes;

      await itemRepository.markAllSynced();
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
  Future<JsonResponse> pushOnlyIfPending() async {
    final pendingRes = await itemRepository.getPendingSync();
    if (!pendingRes.success) return pendingRes;
    final pending = pendingRes.data as List<Item>;
    if (pending.isEmpty) {
      return JsonResponse.success(message: 'Nothing pending');
    }
    return performSync();
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
      await itemRepository.markAllUnsynced();
      return JsonResponse.success(message: 'Cloud backup deleted');
    } catch (e) {
      return JsonResponse.failure(message: 'Delete failed: $e');
    }
  }
}
