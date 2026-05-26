import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/symptom_entry.dart';
import '../../data/repositories/symptom_repository.dart';

part 'symptom_event.dart';
part 'symptom_state.dart';

/// [SymptomBloc] — Style A. Holds every non-deleted symptom entry.
///
/// Events:
/// 1) [WatchSymptoms] — subscribe to repo stream.
/// 2) [SymptomsUpdated] — internal, fires on stream emit.
/// 3) [SaveSymptomsForDay] — upsert symptoms for a given date.
class SymptomBloc extends Bloc<SymptomEvent, SymptomState> {
  SymptomBloc({required this.repository}) : super(const SymptomState()) {
    on<WatchSymptoms>(_onWatch);
    on<SymptomsUpdated>(_onUpdated);
    on<SaveSymptomsForDay>(_onSave);
  }

  final SymptomRepository repository;
  StreamSubscription<List<SymptomEntry>>? _sub;

  FutureOr<void> _onWatch(WatchSymptoms event, Emitter<SymptomState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (entries) => add(SymptomsUpdated(entries: entries)),
          onError: (Object err) =>
              add(SymptomsUpdated(entries: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(
      SymptomsUpdated event, Emitter<SymptomState> emit) {
    emit(state.copyWith(
      isLoading: false,
      entries: event.entries,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(
      SaveSymptomsForDay event, Emitter<SymptomState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    final res = await repository.saveForDay(
      date: event.date,
      symptoms: event.symptoms,
    );
    emit(state.copyWith(
      isLoading: false,
      message: res.success ? res.message : '',
      error: res.success ? '' : res.message,
    ));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
