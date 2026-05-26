# Sync Logic Specification

The sync engine is the hardest part of this app. This document specifies it precisely.

## 1. Data Contract

Every item has these sync fields:

| Field | Type | Purpose |
|---|---|---|
| `id` | `String` (UUID v4) | Stable identifier across devices |
| `updatedAt` | `DateTime` (UTC) | Last modification timestamp |
| `deleted` | `bool` | Soft delete flag |
| `syncedToDrive` | `bool` | Local-only dirty flag (not synced to Drive) |

**Rule:** Every save MUST update `updatedAt = DateTime.now().toUtc()` and set `syncedToDrive = false`.

## 2. The Merge Algorithm

```
function merge(localItems, remoteItems) -> mergedItems:
    map = {}                              # uuid -> item

    for item in localItems:
        map[item.id] = item

    for remoteItem in remoteItems:
        if remoteItem.id not in map:
            map[remoteItem.id] = remoteItem
        else:
            localItem = map[remoteItem.id]
            if remoteItem.updatedAt > localItem.updatedAt:
                map[remoteItem.id] = remoteItem
            elif remoteItem.updatedAt == localItem.updatedAt:
                # Tiebreak: keep local (we trust local more)
                pass
            # else: keep local (already in map)

    return map.values()
```

## 3. Full Sync Flow

```
function performSync():
    if not driveEnabled or not signedIn:
        return SyncResult.skipped()

    acquire(syncLock)
    try:
        # 1. PULL
        remoteFileId = driveDataSource.findBackupFileId()
        if remoteFileId == null:
            remoteSnapshot = BackupSnapshot.empty()
        else:
            remoteSnapshot = driveDataSource.pullBackup(remoteFileId)

        # 2. READ LOCAL (including soft-deleted)
        localItems = localDataSource.getAllIncludingDeleted()

        # 3. MERGE
        merged = merge(localItems, remoteSnapshot.items)

        # 4. WRITE MERGED BACK TO LOCAL
        localDataSource.replaceAll(merged)

        # 5. PUSH
        newSnapshot = BackupSnapshot(
            version: 1,
            lastSyncedAt: now(),
            items: merged
        )
        driveDataSource.pushBackup(newSnapshot, remoteFileId)

        # 6. MARK ALL AS SYNCED
        localDataSource.markAllSynced()

        # 7. PERSIST TIMESTAMP
        prefs.setString('last_synced_at', now().toIso8601String())

        return SyncResult.success()
    catch e:
        return SyncResult.error(e)
    finally:
        release(syncLock)
```

## 4. Concurrency

Use a `Completer`-based lock to prevent concurrent sync runs:

```dart
class SyncService {
  Completer<void>? _activeSyncCompleter;

  Future<SyncResult> performSync() async {
    if (_activeSyncCompleter != null) {
      await _activeSyncCompleter!.future;
      return SyncResult.skipped(reason: 'Already syncing');
    }
    _activeSyncCompleter = Completer<void>();
    try {
      // ... actual sync ...
      return result;
    } finally {
      _activeSyncCompleter!.complete();
      _activeSyncCompleter = null;
    }
  }
}
```

## 5. Trigger Matrix

| Event | Action | Debounced? |
|---|---|---|
| App launch (Drive enabled) | Full sync | No, immediate |
| Local item saved | Push only (no pull) | Yes, 5s |
| Local item deleted | Push only | Yes, 5s |
| Connectivity restored | Push pending if any | No |
| User taps "Sync Now" | Full sync | No |
| `AppLifecycleState.resumed` AND >5min since last sync | Full sync | No |
| User signs out | Cancel pending, clear state | — |
| User toggles Drive off | Cancel pending, clear scheduled | — |
| User toggles Drive on after being off | Full sync | No |

## 6. Edge Cases

### 6.1 First-Time Drive Enable (Has Local Data)

User has been using app offline. Now grants Drive permission.

- `findBackupFileId()` returns `null`
- `remoteSnapshot` becomes empty
- Merge = all local items
- Push creates `backup.json` with full local data
- Done

### 6.2 New Install on Existing Account

User reinstalls. Signs in with same Google account.

- Local DB is empty
- `findBackupFileId()` returns existing file ID
- Pull retrieves all items
- Merge = all remote items (nothing in local to compare)
- Replace local DB with merged set
- Push (no-op effectively, same data)
- App now shows all historical data

### 6.3 Concurrent Edit on Two Devices

Device A edits item X at 10:00:00, hasn't synced.
Device B edits item X at 10:00:05, syncs at 10:00:10.
Device A syncs at 10:00:15.

- Device A pulls B's version (updatedAt = 10:00:05)
- Local A has its own edit (updatedAt = 10:00:00)
- Merge: B's wins (later timestamp)
- Local A's edit is **lost** — this is by-design LWW
- Push: A uploads B's version (idempotent)

**Mitigation for important data:** Show user a "last synced X ago" indicator so they know to sync before editing.

### 6.4 Delete on A, Edit on B

A deletes item X at 10:00:00 (sets `deleted=true`, `updatedAt=10:00:00`).
B edits item X at 10:00:05 (sets `deleted=false`, `updatedAt=10:00:05`).

- Merge: B's wins because later. Item is restored.
- This is correct: "B edited it later means B wanted it alive."

### 6.5 Drive Quota Exceeded

`pushBackup()` throws `DetailedApiRequestError` with status 403.

- Catch, return `SyncResult.error('Drive storage full')`
- Local data unaffected
- SyncCubit emits `Error` state
- UI shows banner: "Drive is full. Free up space and try again."

### 6.6 Token Expired

Any Drive call throws 401.

- Refresh token via `googleSignIn.signInSilently()`
- If silent refresh fails, sign user out, show re-auth prompt
- Local data unaffected

### 6.7 Corrupted backup.json

`jsonDecode` throws, or schema is wrong.

- Log the error with full stack
- Treat as empty remote snapshot for this sync
- **Do NOT overwrite remote yet** — bail out
- Show user: "Backup file appears corrupted. Restore from cloud or overwrite?"
- Give choices: keep local + overwrite remote, or abort

## 7. Testing Checklist

Unit tests for `SyncService.merge()`:

- [ ] Empty local + empty remote → empty result
- [ ] Empty local + 3 remote → 3 items
- [ ] 3 local + empty remote → 3 items
- [ ] Same UUID, local newer → local wins
- [ ] Same UUID, remote newer → remote wins
- [ ] Same UUID, same timestamp → local wins
- [ ] Local has item with `deleted=true`, remote doesn't have it → item kept (with deleted flag)
- [ ] Local has item with `deleted=true` (newer), remote has same item alive (older) → deleted wins
- [ ] 1000 items each side, all unique → 2000 items in result
- [ ] Identical lists on both sides → no changes

Integration tests:

- [ ] Create item → wait 6s → verify Drive has it (mock)
- [ ] Create item offline → go online → verify push happens
- [ ] Sign out → local data still there
- [ ] Sign in different account → loads that account's data
