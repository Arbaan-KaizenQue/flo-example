import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/cycle_log.dart';
import '../../data/repositories/cycle_log_repository.dart';

part 'cycle_log_event.dart';
part 'cycle_log_state.dart';

/// [CycleLogBloc] — Style A. Holds the live list of [CycleLog]s plus the
/// usual `isLoading` / `error` / `message` bookkeeping.
///
/// Events:
/// 1) [WatchCycleLogs] — subscribe to the repo stream.
/// 2) [CycleLogsUpdated] — internal, fires when the stream emits.
/// 3) [SaveCycleLog] — create or update.
/// 4) [DeleteCycleLog] — soft delete by id.
class CycleLogBloc extends Bloc<CycleLogEvent, CycleLogState> {
  CycleLogBloc({required this.repository}) : super(const CycleLogState()) {
    on<WatchCycleLogs>(_onWatch);
    on<CycleLogsUpdated>(_onUpdated);
    on<SaveCycleLog>(_onSave);
    on<DeleteCycleLog>(_onDelete);
  }

  final CycleLogRepository repository;
  StreamSubscription<List<CycleLog>>? _sub;

  FutureOr<void> _onWatch(
      WatchCycleLogs event, Emitter<CycleLogState> emit) {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    _sub?.cancel();
    _sub = repository.watchAll().listen(
          (logs) => add(CycleLogsUpdated(logs: logs)),
          onError: (Object err) =>
              add(CycleLogsUpdated(logs: const [], error: err.toString())),
        );
  }

  FutureOr<void> _onUpdated(
      CycleLogsUpdated event, Emitter<CycleLogState> emit) {
    emit(state.copyWith(
      isLoading: false,
      logs: event.logs,
      error: event.error,
    ));
  }

  FutureOr<void> _onSave(
      SaveCycleLog event, Emitter<CycleLogState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    final res = event.existing == null
        ? await repository.create(
            startDate: event.startDate,
            endDate: event.endDate,
            flow: event.flow,
          )
        : await repository.update(
            event.existing!.copyWith(
              startDate: event.startDate,
              endDate: event.endDate,
              flow: event.flow,
            ),
          );
    emit(state.copyWith(
      isLoading: false,
      message: res.success ? res.message : '',
      error: res.success ? '' : res.message,
    ));
  }

  FutureOr<void> _onDelete(
      DeleteCycleLog event, Emitter<CycleLogState> emit) async {
    final res = await repository.softDelete(event.id);
    if (!res.success) emit(state.copyWith(error: res.message));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
