part of 'prediction_bloc.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

class WatchCycleHistory extends PredictionEvent {
  const WatchCycleHistory();
}

class CycleHistoryUpdated extends PredictionEvent {
  const CycleHistoryUpdated({required this.logs, this.error = ''});

  final List<CycleLog> logs;
  final String error;

  @override
  List<Object> get props => [logs, error];
}
