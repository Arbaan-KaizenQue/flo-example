part of 'cycle_log_bloc.dart';

class CycleLogState extends Equatable {
  const CycleLogState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.logs = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<CycleLog> logs;

  CycleLogState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<CycleLog>? logs,
  }) =>
      CycleLogState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        logs: logs ?? this.logs,
      );

  /// Returns the set of day-only [DateTime]s covered by any non-deleted log.
  /// Used by the calendar to paint period dots.
  Set<DateTime> get periodDays {
    final out = <DateTime>{};
    for (final log in logs) {
      final start = DateTime(
        log.startDate.year,
        log.startDate.month,
        log.startDate.day,
      );
      final end = log.endDate == null
          ? start
          : DateTime(
              log.endDate!.year,
              log.endDate!.month,
              log.endDate!.day,
            );
      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        out.add(d);
      }
    }
    return out;
  }

  /// Returns the log (if any) whose [startDate]..[endDate] range contains [day].
  CycleLog? logForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final log in logs) {
      final start = DateTime(
        log.startDate.year,
        log.startDate.month,
        log.startDate.day,
      );
      final end = log.endDate == null
          ? start
          : DateTime(
              log.endDate!.year,
              log.endDate!.month,
              log.endDate!.day,
            );
      if (!target.isBefore(start) && !target.isAfter(end)) return log;
    }
    return null;
  }

  @override
  List<Object> get props => [isLoading, error, message, logs];
}
