part of 'note_bloc.dart';

abstract class NoteEvent extends Equatable {
  const NoteEvent();

  @override
  List<Object?> get props => [];
}

class WatchNotes extends NoteEvent {
  const WatchNotes();
}

class NotesUpdated extends NoteEvent {
  const NotesUpdated({required this.notes, this.error = ''});

  final List<Note> notes;
  final String error;

  @override
  List<Object> get props => [notes, error];
}

class SaveNote extends NoteEvent {
  const SaveNote({
    required this.date,
    required this.title,
    required this.body,
  });

  final DateTime date;
  final String title;
  final String body;

  @override
  List<Object> get props => [date, title, body];
}

class DeleteNote extends NoteEvent {
  const DeleteNote({required this.id});

  final String id;

  @override
  List<Object> get props => [id];
}
