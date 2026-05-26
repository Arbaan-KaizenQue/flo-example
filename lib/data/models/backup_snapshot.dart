import 'package:equatable/equatable.dart';

/// [BackupSnapshot] — minimal Drive-side metadata for the backup file.
///
/// Feature data (cycle logs, symptoms, mood, etc.) will be added to this
/// snapshot as part of Feature 14 (Export/Backup) / Feature 16 (Multi-Device
/// Sync). Until then this snapshot is metadata-only and pushing it is
/// effectively a no-op.
class BackupSnapshot extends Equatable {
  const BackupSnapshot({
    required this.version,
    required this.lastSyncedAt,
  });

  final int version;
  final DateTime lastSyncedAt;

  factory BackupSnapshot.empty() => BackupSnapshot(
        version: 1,
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) => BackupSnapshot(
        version: int.tryParse('${json['version']}') ?? 1,
        lastSyncedAt: DateTime.tryParse('${json['lastSyncedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [version, lastSyncedAt];
}
