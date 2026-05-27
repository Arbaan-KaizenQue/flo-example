part of 'mood_bloc.dart';

class MoodState extends Equatable {
  const MoodState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.entries = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<MoodEntry> entries;

  MoodState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<MoodEntry>? entries,
  }) =>
      MoodState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        entries: entries ?? this.entries,
      );

  MoodEntry? entryForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final e in entries) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      if (d == target) return e;
    }
    return null;
  }

  @override
  List<Object> get props => [isLoading, error, message, entries];
}
