part of 'note_bloc.dart';

class NoteState extends Equatable {
  const NoteState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.notes = const [],
  });

  final bool isLoading;
  final String error;
  final String message;
  final List<Note> notes;

  NoteState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    List<Note>? notes,
  }) =>
      NoteState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        notes: notes ?? this.notes,
      );

  Note? noteForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    for (final n in notes) {
      final d = DateTime(n.date.year, n.date.month, n.date.day);
      if (d == target) return n;
    }
    return null;
  }

  @override
  List<Object> get props => [isLoading, error, message, notes];
}
