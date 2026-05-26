import 'package:equatable/equatable.dart';

class SleepLog extends Equatable {
  const SleepLog({
    required this.id,
    required this.date,
    this.hours = 0,
    this.quality = 'good',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime date;
  final double hours;
  final String quality;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  factory SleepLog.fromJson(Map<String, dynamic> json) => SleepLog(
        id: json['id']?.toString() ?? '',
        date: DateTime.tryParse('${json['date']}')?.toUtc() ??
            DateTime.now().toUtc(),
        hours: double.tryParse('${json['hours']}') ?? 0,
        quality: json['quality']?.toString() ?? 'good',
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'hours': hours,
        'quality': quality,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  SleepLog copyWith({
    double? hours,
    String? quality,
    DateTime? updatedAt,
    bool? deleted,
  }) =>
      SleepLog(
        id: id,
        date: date,
        hours: hours ?? this.hours,
        quality: quality ?? this.quality,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, date, hours, quality, createdAt, updatedAt, deleted];
}
