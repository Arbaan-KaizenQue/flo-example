part of 'water_bloc.dart';

class WaterState extends Equatable {
  const WaterState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.logs = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<WaterLog> logs;

  WaterState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<WaterLog>? logs,
  }) =>
      WaterState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        logs: logs ?? this.logs,
      );

  WaterLog? logForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final l in logs) {
      final d = DateTime(l.date.year, l.date.month, l.date.day);
      if (d == target) return l;
    }
    return null;
  }

  @override
  List<Object> get props => [isLoading, error, message, logs];
}
