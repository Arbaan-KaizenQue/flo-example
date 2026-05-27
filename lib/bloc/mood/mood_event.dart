part of 'mood_bloc.dart';

abstract class MoodEvent extends Equatable {
  const MoodEvent();

  @override
  List<Object?> get props => [];
}

class WatchMood extends MoodEvent {
  const WatchMood();
}

class MoodUpdated extends MoodEvent {
  const MoodUpdated({required this.entries, this.error = ''});

  final List<MoodEntry> entries;
  final String error;

  @override
  List<Object> get props => [entries, error];
}

class SaveMoodForDay extends MoodEvent {
  const SaveMoodForDay({
    required this.date,
    required this.mood,
    this.note = '',
  });

  final DateTime date;
  final String mood;
  final String note;

  @override
  List<Object> get props => [date, mood, note];
}
