part of 'water_bloc.dart';

abstract class WaterEvent extends Equatable {
  const WaterEvent();

  @override
  List<Object?> get props => [];
}

class WatchWater extends WaterEvent {
  const WatchWater();
}

class WaterUpdated extends WaterEvent {
  const WaterUpdated({required this.logs, this.error = ''});

  final List<WaterLog> logs;
  final String error;

  @override
  List<Object> get props => [logs, error];
}

class AddWater extends WaterEvent {
  const AddWater({required this.date, required this.ml});

  final DateTime date;
  final int ml;

  @override
  List<Object> get props => [date, ml];
}

class SetWaterGoal extends WaterEvent {
  const SetWaterGoal({required this.date, required this.goalMl});

  final DateTime date;
  final int goalMl;

  @override
  List<Object> get props => [date, goalMl];
}
