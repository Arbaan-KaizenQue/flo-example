import 'package:equatable/equatable.dart';

/// [CycleLog] — immutable view of one cycle log.
class CycleLog extends Equatable {
  const CycleLog({
    required this.id,
    required this.startDate,
    this.endDate,
    this.flow = 'medium',
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final String flow;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool deleted;

  factory CycleLog.fromJson(Map<String, dynamic> json) => CycleLog(
        id: json['id']?.toString() ?? '',
        startDate: DateTime.tryParse('${json['startDate']}')?.toUtc() ??
            DateTime.now().toUtc(),
        endDate: json['endDate'] == null
            ? null
            : DateTime.tryParse('${json['endDate']}')?.toUtc(),
        flow: json['flow']?.toString() ?? 'medium',
        createdAt: DateTime.tryParse('${json['createdAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        updatedAt: DateTime.tryParse('${json['updatedAt']}')?.toUtc() ??
            DateTime.now().toUtc(),
        deleted: bool.tryParse('${json['deleted']}') ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate?.toUtc().toIso8601String(),
        'flow': flow,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'deleted': deleted,
      };

  CycleLog copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? flow,
    DateTime? updatedAt,
    bool? deleted,
    bool clearEndDate = false,
  }) =>
      CycleLog(
        id: id,
        startDate: startDate ?? this.startDate,
        endDate: clearEndDate ? null : (endDate ?? this.endDate),
        flow: flow ?? this.flow,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deleted: deleted ?? this.deleted,
      );

  @override
  List<Object?> get props =>
      [id, startDate, endDate, flow, createdAt, updatedAt, deleted];
}
