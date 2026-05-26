part of 'sleep_bloc.dart';

abstract class SleepEvent extends Equatable {
  const SleepEvent();

  @override
  List<Object?> get props => [];
}

class WatchSleep extends SleepEvent {
  const WatchSleep();
}

class SleepUpdated extends SleepEvent {
  const SleepUpdated({required this.logs, this.error = ''});

  final List<SleepLog> logs;
  final String error;

  @override
  List<Object> get props => [logs, error];
}

class SaveSleepForDay extends SleepEvent {
  const SaveSleepForDay({
    required this.date,
    required this.hours,
    required this.quality,
  });

  final DateTime date;
  final double hours;
  final String quality;

  @override
  List<Object> get props => [date, hours, quality];
}
