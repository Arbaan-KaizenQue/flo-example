import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/sleep_log.dart';
import '../../data/repositories/sleep_repository.dart';

part 'sleep_event.dart';
part 'sleep_state.dart';

class SleepBloc extends Bloc<SleepEvent, SleepState> {
  SleepBloc({required this.repository}) : super(const SleepState()) {
    on<WatchSleep>(_onWatch);
    on<SleepUpdated>(_onUpdated);
    on<SaveSleepForDay>(_onSave);
  }

  final SleepRepository repository;
  StreamSubscription<List<SleepLog>>? _sub;

  FutureOr<void> _onWatch(WatchSleep event, Emitter<SleepState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (logs) => add(SleepUpdated(logs: logs)),
          onError: (Object err) =>
              add(SleepUpdated(logs: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(
      SleepUpdated event, Emitter<SleepState> emit) {
    emit(state.copyWith(
      isLoading: false,
      logs: event.logs,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(
      SaveSleepForDay event, Emitter<SleepState> emit) async {
    final res = await repository.saveForDay(
      date: event.date,
      hours: event.hours,
      quality: event.quality,
    );
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
