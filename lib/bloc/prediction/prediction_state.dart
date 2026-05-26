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
      ];
}
