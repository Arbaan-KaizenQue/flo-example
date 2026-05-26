part of 'weight_bloc.dart';

abstract class WeightEvent extends Equatable {
  const WeightEvent();

  @override
  List<Object?> get props => [];
}

class WatchWeight extends WeightEvent {
  const WatchWeight();
}

class WeightUpdated extends WeightEvent {
  const WeightUpdated({required this.logs, this.error = ''});

  final List<WeightLog> logs;
  final String error;

  @override
  List<Object> get props => [logs, error];
}

class SaveWeightForDay extends WeightEvent {
  const SaveWeightForDay({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;

  @override
  List<Object> get props => [date, weightKg];
}
