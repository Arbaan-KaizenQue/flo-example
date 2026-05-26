import 'package:equatable/equatable.dart';

class WeightLog extends Equatable {
  const WeightLog({
    required this.id,
    required this.date,
    this.weightKg = 0,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final double weightKg;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  factory WeightLog.fromJson(Map<String, dynamic> json) => WeightLog(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        weightKg: double.tryParse('${json['weightKg']}') ?? 0,
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'weightKg': weightKg,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  WeightLog copyWith({
    double? weightKg,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      WeightLog(
        id: id,
        date: date,
        weightKg: weightKg ?? this.weightKg,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, weightKg, createdAt, updatedAt, deleted];
}
