part of 'prediction_bloc.dart';

class PredictionState extends Equatable {
  const PredictionState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.averageCycleLength = 28,
    this.lastPeriodStart,
    this.nextPredictedPeriodStart,
    this.nextPredictedPeriodEnd,
    this.daysUntilNextPeriod,
    this.dayOfCycle,
    this.ovulationDay,
    this.fertileWindowStart,
    this.fertileWindowEnd,
  });

  final bool isLoading;
  final String error;
  final String message;

  final int averageCycleLength;
  final DateTime? lastPeriodStart;
  final DateTime? nextPredictedPeriodStart;
  final DateTime? nextPredictedPeriodEnd;

  /// Negative when the predicted period date has already passed.
  final int? daysUntilNextPeriod;

  /// 1-based day index inside the current cycle (e.g. 'Day 14').
  final int? dayOfCycle;

  // Feature 10 — Fertility Window
  final DateTime? ovulationDay;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;

  bool get hasPrediction => nextPredictedPeriodStart != null;

  /// Set of day-only DateTimes that should be rendered as predicted-period
  /// days on the calendar (Feature 09).
  Set<DateTime> get predictedPeriodDays {
    final start = nextPredictedPeriodStart;
    final end = nextPredictedPeriodEnd ?? start;
    if (start == null || end == null) return const {};
    final out = <DateTime>{};
    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }

  /// Set of day-only DateTimes inside the fertile window (Feature 10).
  Set<DateTime> get fertileDays {
    final start = fertileWindowStart;
    final end = fertileWindowEnd;
    if (start == null || end == null) return const {};
    final out = <DateTime>{};
    for (var d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }

  /// True if today falls inside [fertileWindowStart]..[fertileWindowEnd].
  bool get isFertileToday {
    final start = fertileWindowStart;
    final end = fertileWindowEnd;
    if (start == null || end == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }

  PredictionState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    int? averageCycleLength,
    DateTime? lastPeriodStart,
    DateTime? nextPredictedPeriodStart,
    DateTime? nextPredictedPeriodEnd,
    int? daysUntilNextPeriod,
    int? dayOfCycle,
    DateTime? ovulationDay,
    DateTime? fertileWindowStart,
    DateTime? fertileWindowEnd,
  }) =>
      PredictionState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        averageCycleLength: averageCycleLength ?? this.averageCycleLength,
        lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
        nextPredictedPeriodStart:
            nextPredictedPeriodStart ?? this.nextPredictedPeriodStart,
        nextPredictedPeriodEnd:
            nextPredictedPeriodEnd ?? this.nextPredictedPeriodEnd,
        daysUntilNextPeriod:
            daysUntilNextPeriod ?? this.daysUntilNextPeriod,
        dayOfCycle: dayOfCycle ?? this.dayOfCycle,
        ovulationDay: ovulationDay ?? this.ovulationDay,
        fertileWindowStart: fertileWindowStart ?? this.fertileWindowStart,
        fertileWindowEnd: fertileWindowEnd ?? this.fertileWindowEnd,
      );

  @override
  List<Object?> get props => [
        isLoading,
        error,
        message,
        averageCycleLength,
        lastPeriodStart,
        nextPredictedPeriodStart,
        nextPredictedPeriodEnd,
        daysUntilNextPeriod,
        dayOfCycle,
        ovulationDay,
        fertileWindowStart,
        fertileWindowEnd,
      ];
}
