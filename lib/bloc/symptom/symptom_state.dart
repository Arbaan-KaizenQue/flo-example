part of 'symptom_bloc.dart';

class SymptomState extends Equatable {
  const SymptomState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.entries = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<SymptomEntry> entries;

  SymptomState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<SymptomEntry>? entries,
  }) =>
      SymptomState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        entries: entries ?? this.entries,
      );

  /// Returns the [SymptomEntry] for [day] if one exists (non-deleted).
  SymptomEntry? entryForDay(DateTime day) {
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
