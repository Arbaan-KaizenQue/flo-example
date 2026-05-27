import 'package:equatable/equatable.dart';

class MoodEntry extends Equatable {
  const MoodEntry({
    required this.id,
    required this.date,
    this.mood = 'okay',
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final String mood;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        mood: json['mood']?.toString() ?? 'okay',
        note: json['note']?.toString() ?? '',
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'mood': mood,
        'note': note,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  MoodEntry copyWith({
    String? mood,
    String? note,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      MoodEntry(
        id: id,
        date: date,
        mood: mood ?? this.mood,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, mood, note, createdAt, updatedAt, deleted];
}
