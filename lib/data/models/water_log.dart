import 'package:equatable/equatable.dart';

class WaterLog extends Equatable {
  const WaterLog({
    required this.id,
    required this.date,
    this.amountMl = 0,
    this.goalMl = 2000,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final int amountMl;
  final int goalMl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  double get progress =>
      goalMl <= 0 ? 0.0 : (amountMl / goalMl).clamp(0.0, 1.0).toDouble();

  factory WaterLog.fromJson(Map<String, dynamic> json) => WaterLog(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        amountMl: int.tryParse('${json['amountMl']}') ?? 0,
        goalMl: int.tryParse('${json['goalMl']}') ?? 2000,
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'amountMl': amountMl,
        'goalMl': goalMl,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  WaterLog copyWith({
    int? amountMl,
    int? goalMl,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      WaterLog(
        id: id,
        date: date,
        amountMl: amountMl ?? this.amountMl,
        goalMl: goalMl ?? this.goalMl,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, amountMl, goalMl, createdAt, updatedAt, deleted];
}
