import 'package:equatable/equatable.dart';

/// [SymptomEntry] — immutable view of one day's symptoms.
class SymptomEntry extends Equatable {
  const SymptomEntry({
    required this.id,
    required this.date,
    this.symptoms = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final List<String> symptoms;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  factory SymptomEntry.fromJson(Map<String, dynamic> json) => SymptomEntry(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        symptoms: (json['symptoms'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'symptoms': symptoms,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  SymptomEntry copyWith({
    List<String>? symptoms,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      SymptomEntry(
        id: id,
        date: date,
        symptoms: symptoms ?? this.symptoms,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, symptoms, createdAt, updatedAt, deleted];
}
