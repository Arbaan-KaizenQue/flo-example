import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/weight_log.dart';
import '../../data/repositories/weight_repository.dart';

part 'weight_event.dart';
part 'weight_state.dart';

class WeightBloc extends Bloc<WeightEvent, WeightState> {
  WeightBloc({required this.repository}) : super(const WeightState()) {
    on<WatchWeight>(_onWatch);
    on<WeightUpdated>(_onUpdated);
    on<SaveWeightForDay>(_onSave);
  }

  final WeightRepository repository;
  StreamSubscription<List<WeightLog>>? _sub;

  FutureOr<void> _onWatch(WatchWeight event, Emitter<WeightState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (logs) => add(WeightUpdated(logs: logs)),
          onError: (Object err) =>
              add(WeightUpdated(logs: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(
      WeightUpdated event, Emitter<WeightState> emit) {
    emit(state.copyWith(
      isLoading: false,
      logs: event.logs,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(
      SaveWeightForDay event, Emitter<WeightState> emit) async {
    final res = await repository.saveForDay(
      date: event.date,
      weightKg: event.weightKg,
    );
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
