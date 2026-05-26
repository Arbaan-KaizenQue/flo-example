import 'package:equatable/equatable.dart';

class Note extends Equatable {
  const Note({
    required this.id,
    required this.date,
    this.title = '',
    this.body = '',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'title': title,
        'body': body,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  Note copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      Note(
        id: id,
        date: date,
        title: title ?? this.title,
        body: body ?? this.body,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, title, body, createdAt, updatedAt, deleted];
}
