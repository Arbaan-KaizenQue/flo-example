import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/cycle_log.dart';
import '../../data/repositories/cycle_log_repository.dart';

part 'prediction_event.dart';
part 'prediction_state.dart';

/// [PredictionBloc] — derives cycle-prediction info from the user's
/// [CycleLog] history. No entity of its own; just a stateful calculator.
///
/// Defaults:
/// - If we have ≥ 2 prior periods → use their average gap.
/// - If only 1 → assume 28-day cycle.
/// - If none → emit no prediction.
///
/// Feature 10 (Fertility Window) extends this with ovulation + fertile
/// window derived from the same prediction.
class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  PredictionBloc({
    required this.cycleLogRepository,
    this.defaultCycleLength = 28,
    this.lutealPhaseLength = 14,
  }) : super(const PredictionState()) {
    on<WatchCycleHistory>(_onWatch);
    on<CycleHistoryUpdated>(_onUpdated);
  }

  final CycleLogRepository cycleLogRepository;
  final int defaultCycleLength;
  final int lutealPhaseLength;

  StreamSubscription<List<CycleLog>>? _sub;

  FutureOr<void> _onWatch(
      WatchCycleHistory event, Emitter<PredictionState> emit) {
    emit(state.copyWith(isLoading: true, error: ''));
    _sub?.cancel();
    _sub = cycleLogRepository.watchAll().listen(
          (logs) => add(CycleHistoryUpdated(logs: logs)),
          onError: (Object err) => add(
            CycleHistoryUpdated(logs: const [], error: err.toString()),
          ),
        );
  }

  FutureOr<void> _onUpdated(
      CycleHistoryUpdated event, Emitter<PredictionState> emit) {
    emit(_compute(event.logs).copyWith(
      isLoading: false,
      error: event.error,
    ));
  }

  PredictionState _compute(List<CycleLog> logs) {
    if (logs.isEmpty) {
      return PredictionState(
        isLoading: false,
        averageCycleLength: defaultCycleLength,
      );
    }

    // logs already sorted desc by startDate (per repo / box query).
    final starts = logs.map((l) => _dayOnly(l.startDate)).toList();
    starts.sort((a, b) => a.compareTo(b)); // ascending for diff calc

    int avg = defaultCycleLength;
    if (starts.length >= 2) {
      final diffs = <int>[];
      for (var i = 1; i < starts.length; i++) {
        diffs.add(starts[i].difference(starts[i - 1]).inDays);
      }
      final filtered = diffs.where((d) => d >= 18 && d <= 45).toList();
      if (filtered.isNotEmpty) {
        final sum = filtered.fold<int>(0, (s, d) => s + d);
        avg = (sum / filtered.length).round();
      }
    }

    final lastStart = starts.last;
    final nextStart = lastStart.add(Duration(days: avg));
    // assume the period itself lasts as long as the last logged one (or 5 days)
    final lastLog = logs.first; // most recent
    final lastDuration = lastLog.endDate == null
        ? 5
        : _dayOnly(lastLog.endDate!).difference(lastStart).inDays + 1;
    final nextEnd =
        nextStart.add(Duration(days: lastDuration.clamp(3, 10) - 1));

    final today = _dayOnly(DateTime.now());
    final daysUntilNext = nextStart.difference(today).inDays;
    final dayOfCycle = today.difference(lastStart).inDays + 1;

    // Feature 10 — Fertility window:
    //  Ovulation ≈ next period start − [lutealPhaseLength] days.
    //  Fertile window = ovulation − 5 days .. ovulation + 1 day (6-day span).
    final ovulation =
        nextStart.subtract(Duration(days: lutealPhaseLength));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    return PredictionState(
      isLoading: false,
      averageCycleLength: avg,
      lastPeriodStart: lastStart,
      nextPredictedPeriodStart: nextStart,
      nextPredictedPeriodEnd: nextEnd,
      daysUntilNextPeriod: daysUntilNext,
      dayOfCycle: dayOfCycle > 0 ? dayOfCycle : null,
      ovulationDay: ovulation,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
    );
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
