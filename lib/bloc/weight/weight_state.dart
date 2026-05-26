part of 'weight_bloc.dart';

class WeightState extends Equatable {
  const WeightState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.logs = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<WeightLog> logs;

  WeightState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<WeightLog>? logs,
  }) =>
      WeightState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        logs: logs ?? this.logs,
      );

  WeightLog? logForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final l in logs) {
      final d = DateTime(l.date.year, l.date.month, l.date.day);
      if (d == target) return l;
    }
    return null;
  }

  /// Most recent (latest-by-date) log, regardless of which day is shown.
  WeightLog? get latest => logs.isEmpty ? null : logs.first;

  @override
  List<Object> get props => [isLoading, error, message, logs];
}
