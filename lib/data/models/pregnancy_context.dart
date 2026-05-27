import 'package:equatable/equatable.dart';

/// [PregnancyContext] — derived pregnancy state. Computed from the stored
/// LMP (last menstrual period start) date. Standard 280-day (40-week)
/// pregnancy calendar used.
class PregnancyContext extends Equatable {
  const PregnancyContext({
    required this.lmp,
    required this.dueDate,
    required this.weeksPregnant,
    required this.daysPregnant,
    required this.trimester,
  });

  /// Last menstrual period start (UTC, day-only).
  final DateTime lmp;

  /// Standard EDD = LMP + 280 days.
  final DateTime dueDate;

  /// 0–42 typically. Computed as (today − LMP) / 7 floored.
  final int weeksPregnant;

  final int daysPregnant;

  /// 1, 2, or 3.
  final int trimester;

  factory PregnancyContext.fromLmp(DateTime lmp, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final lmpDay = DateTime(lmp.year, lmp.month, lmp.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final days = todayDay.difference(lmpDay).inDays;
    final weeks = days ~/ 7;
    final trim = weeks < 13
        ? 1
        : weeks < 27
            ? 2
            : 3;
    return PregnancyContext(
      lmp: lmpDay,
      dueDate: lmpDay.add(const Duration(days: 280)),
      weeksPregnant: weeks,
      daysPregnant: days,
      trimester: trim,
    );
  }

  Map<String, dynamic> toJson() => {
        'lmp': lmp.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'weeksPregnant': weeksPregnant,
        'daysPregnant': daysPregnant,
        'trimester': trimester,
      };

  @override
  List<Object?> get props =>
      [lmp, dueDate, weeksPregnant, daysPregnant, trimester];
}
