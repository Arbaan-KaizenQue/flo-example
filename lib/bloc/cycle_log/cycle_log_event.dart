part of 'cycle_log_bloc.dart';

abstract class CycleLogEvent extends Equatable {
  const CycleLogEvent();

  @override
  List<Object?> get props => [];
}

class WatchCycleLogs extends CycleLogEvent {
  const WatchCycleLogs();
}

class CycleLogsUpdated extends CycleLogEvent {
  const CycleLogsUpdated({required this.logs, this.error = ''});

  final List<CycleLog> logs;
  final String error;

  @override
  List<Object> get props => [logs, error];
}

class SaveCycleLog extends CycleLogEvent {
  const SaveCycleLog({
    required this.startDate,
    this.endDate,
    this.flow = 'medium',
    this.existing,
  });

  final DateTime startDate;
  final DateTime? endDate;
  final String flow;
  final CycleLog? existing;

  @override
  List<Object?> get props => [startDate, endDate, flow, existing];
}

class DeleteCycleLog extends CycleLogEvent {
  const DeleteCycleLog({required this.id});

  final String id;

  @override
  List<Object> get props => [id];
}
