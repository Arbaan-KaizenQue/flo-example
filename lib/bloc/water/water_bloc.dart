import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/water_log.dart';
import '../../data/repositories/water_repository.dart';

part 'water_event.dart';
part 'water_state.dart';

class WaterBloc extends Bloc<WaterEvent, WaterState> {
  WaterBloc({required this.repository}) : super(const WaterState()) {
    on<WatchWater>(_onWatch);
    on<WaterUpdated>(_onUpdated);
    on<AddWater>(_onAdd);
    on<SetWaterGoal>(_onSetGoal);
  }

  final WaterRepository repository;
  StreamSubscription<List<WaterLog>>? _sub;

  FutureOr<void> _onWatch(WatchWater event, Emitter<WaterState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (logs) => add(WaterUpdated(logs: logs)),
          onError: (Object err) =>
              add(WaterUpdated(logs: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(
      WaterUpdated event, Emitter<WaterState> emit) {
    emit(state.copyWith(
      isLoading: false,
      logs: event.logs,
      error: event.error,
    ));
  }

  FutureOr<void> _onAdd(AddWater event, Emitter<WaterState> emit) async {
    final res = await repository.addAmount(date: event.date, ml: event.ml);
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  FutureOr<void> _onSetGoal(
      SetWaterGoal event, Emitter<WaterState> emit) async {
    final res =
        await repository.setGoal(date: event.date, goalMl: event.goalMl);
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
