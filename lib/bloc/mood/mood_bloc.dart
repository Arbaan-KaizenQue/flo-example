import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/mood_entry.dart';
import '../../data/repositories/mood_repository.dart';

part 'mood_event.dart';
part 'mood_state.dart';

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  MoodBloc({required this.repository}) : super(const MoodState()) {
    on<WatchMood>(_onWatch);
    on<MoodUpdated>(_onUpdated);
    on<SaveMoodForDay>(_onSave);
  }

  final MoodRepository repository;
  StreamSubscription<List<MoodEntry>>? _sub;

  FutureOr<void> _onWatch(WatchMood event, Emitter<MoodState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (entries) => add(MoodUpdated(entries: entries)),
          onError: (Object err) =>
              add(MoodUpdated(entries: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(MoodUpdated event, Emitter<MoodState> emit) {
    emit(state.copyWith(
      isLoading: false,
      entries: event.entries,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(SaveMoodForDay event, Emitter<MoodState> emit) async {
    final res = await repository.saveForDay(
      date: event.date,
      mood: event.mood,
      note: event.note,
    );
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
