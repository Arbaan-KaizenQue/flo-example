import 'package:equatable/equatable.dart';

import 'item.dart';

/// [BackupSnapshot] — Drive-side representation of the entire item set.
class BackupSnapshot extends Equatable {
  const BackupSnapshot({
    required this.version,
    required this.lastSyncedAt,
    required this.items,
  });

  final int version;
  final DateTime lastSyncedAt;
  final List<Item> items;

  factory BackupSnapshot.empty() => BackupSnapshot(
        version: 1,
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        items: const [],
      );

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) => BackupSnapshot(
        version: int.tryParse('${json['version']}') ?? 1,
        lastSyncedAt: DateTime.tryParse('${json['lastSyncedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        items: (json['items'] as List?)
                ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [version, lastSyncedAt, items];
}
