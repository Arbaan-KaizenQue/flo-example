import 'package:equatable/equatable.dart';

import 'cycle_log.dart';
import 'mood_entry.dart';
import 'note.dart';
import 'onboarding_answers.dart';
import 'sleep_log.dart';
import 'symptom_entry.dart';
import 'water_log.dart';
import 'weight_log.dart';

/// [BackupSnapshot] — full Drive payload. v2 carries every entity
/// collection so a fresh install can fully restore from Drive.
class BackupSnapshot extends Equatable {
  const BackupSnapshot({
    required this.version,
    required this.lastSyncedAt,
    this.cycleLogs = const [],
    this.symptoms = const [],
    this.water = const [],
    this.sleep = const [],
    this.weight = const [],
    this.notes = const [],
    this.mood = const [],
    this.onboardingAnswers,
  });

  static const int currentVersion = 2;

  final int version;
  final DateTime lastSyncedAt;

  final List<CycleLog> cycleLogs;
  final List<SymptomEntry> symptoms;
  final List<WaterLog> water;
  final List<SleepLog> sleep;
  final List<WeightLog> weight;
  final List<Note> notes;
  final List<MoodEntry> mood;
  final OnboardingAnswers? onboardingAnswers;

  factory BackupSnapshot.empty() => BackupSnapshot(
        version: currentVersion,
        lastSyncedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );

  factory BackupSnapshot.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String key,
      T Function(Map<String, dynamic>) build,
    ) =>
        (json[key] as List?)
            ?.cast<Map<String, dynamic>>()
            .map(build)
            .toList(growable: false) ??
        const [];

    return BackupSnapshot(
      version: int.tryParse('${json['version']}') ?? 1,
      lastSyncedAt: DateTime.tryParse('${json['lastSyncedAt']}')?.toUtc() ??
          DateTime.now().toUtc(),
      cycleLogs: parseList('cycleLogs', CycleLog.fromJson),
      symptoms: parseList('symptoms', SymptomEntry.fromJson),
      water: parseList('water', WaterLog.fromJson),
      sleep: parseList('sleep', SleepLog.fromJson),
      weight: parseList('weight', WeightLog.fromJson),
      notes: parseList('notes', Note.fromJson),
      mood: parseList('mood', MoodEntry.fromJson),
      onboardingAnswers: json['onboardingAnswers'] is Map<String, dynamic>
          ? OnboardingAnswers.fromJson(
              json['onboardingAnswers'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lastSyncedAt': lastSyncedAt.toUtc().toIso8601String(),
        'cycleLogs': cycleLogs.map((e) => e.toJson()).toList(),
        'symptoms': symptoms.map((e) => e.toJson()).toList(),
        'water': water.map((e) => e.toJson()).toList(),
        'sleep': sleep.map((e) => e.toJson()).toList(),
        'weight': weight.map((e) => e.toJson()).toList(),
        'notes': notes.map((e) => e.toJson()).toList(),
        'mood': mood.map((e) => e.toJson()).toList(),
        if (onboardingAnswers != null)
          'onboardingAnswers': onboardingAnswers!.toJson(),
      };

  bool get hasAnyData =>
      cycleLogs.isNotEmpty ||
      symptoms.isNotEmpty ||
      water.isNotEmpty ||
      sleep.isNotEmpty ||
      weight.isNotEmpty ||
      notes.isNotEmpty ||
      mood.isNotEmpty ||
      onboardingAnswers != null;

  @override
  List<Object?> get props => [
        version,
        lastSyncedAt,
        cycleLogs,
        symptoms,
        water,
        sleep,
        weight,
        notes,
        mood,
        onboardingAnswers,
      ];
}
