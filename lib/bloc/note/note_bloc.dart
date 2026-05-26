import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/note.dart';
import '../../data/repositories/note_repository.dart';

part 'note_event.dart';
part 'note_state.dart';

class NoteBloc extends Bloc<NoteEvent, NoteState> {
  NoteBloc({required this.repository}) : super(const NoteState()) {
    on<WatchNotes>(_onWatch);
    on<NotesUpdated>(_onUpdated);
    on<SaveNote>(_onSave);
    on<DeleteNote>(_onDelete);
  }

  final NoteRepository repository;
  StreamSubscription<List<Note>>? _sub;

  FutureOr<void> _onWatch(WatchNotes event, Emitter<NoteState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (notes) => add(NotesUpdated(notes: notes)),
          onError: (Object err) =>
              add(NotesUpdated(notes: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(NotesUpdated event, Emitter<NoteState> emit) {
    emit(state.copyWith(
      isLoading: false,
      notes: event.notes,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(SaveNote event, Emitter<NoteState> emit) async {
    final res = await repository.saveForDay(
      date: event.date,
      title: event.title,
      body: event.body,
    );
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  FutureOr<void> _onDelete(DeleteNote event, Emitter<NoteState> emit) async {
    final res = await repository.softDelete(event.id);
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
