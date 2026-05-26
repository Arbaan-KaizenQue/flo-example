import 'package:equatable/equatable.dart';

/// [Item] — immutable response/local model for a single backed-up item.
class Item extends Equatable {
  const Item({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
    this.syncedToDrive = false,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;
  final bool syncedToDrive;

  factory Item.fromJson(Map<String, dynamic> json) => Item(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
                DateTime.now().toUtc(),
        updatedAt:
            DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
                DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
        // anything coming back from Drive is considered already synced
        syncedToDrive: true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  Item copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    bool? deleted,
    bool? syncedToDrive,
  }) =>
      Item(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
        syncedToDrive: syncedToDrive ?? this.syncedToDrive,
      );

  @override
  List<Object?> get props =>
      [id, title, content, createdAt, updatedAt, deleted, syncedToDrive];
}
