part of 'symptom_bloc.dart';

abstract class SymptomEvent extends Equatable {
  const SymptomEvent();

  @override
  List<Object?> get props => [];
}

class WatchSymptoms extends SymptomEvent {
  const WatchSymptoms();
}

class SymptomsUpdated extends SymptomEvent {
  const SymptomsUpdated({required this.entries, this.error = ''});

  final List<SymptomEntry> entries;
  final String error;

  @override
  List<Object> get props => [entries, error];
}

class SaveSymptomsForDay extends SymptomEvent {
  const SaveSymptomsForDay({required this.date, required this.symptoms});

  final DateTime date;
  final List<String> symptoms;

  @override
  List<Object> get props => [date, symptoms];
}
