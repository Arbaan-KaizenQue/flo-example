import 'package:equatable/equatable.dart';

/// [OnboardingAnswers] — captures every selection from the 5-step onboarding.
/// Single-record model: there's only ever one of these per device.
class OnboardingAnswers extends Equatable {
  const OnboardingAnswers({
    this.ageGroup = '',
    this.cycleLength = '',
    this.symptoms = const [],
    this.goals = const [],
    this.pregnancyStatus = '',
  });

  final String ageGroup;
  final String cycleLength;
  final List<String> symptoms;
  final List<String> goals;
  final String pregnancyStatus;

  factory OnboardingAnswers.fromJson(Map<String, dynamic> json) =>
      OnboardingAnswers(
        ageGroup: json['ageGroup']?.toString() ?? '',
        cycleLength: json['cycleLength']?.toString() ?? '',
        symptoms: (json['symptoms'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        goals: (json['goals'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        pregnancyStatus: json['pregnancyStatus']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'ageGroup': ageGroup,
        'cycleLength': cycleLength,
        'symptoms': symptoms,
        'goals': goals,
        'pregnancyStatus': pregnancyStatus,
      };

  OnboardingAnswers copyWith({
    String? ageGroup,
    String? cycleLength,
    List<String>? symptoms,
    List<String>? goals,
    String? pregnancyStatus,
  }) =>
      OnboardingAnswers(
        ageGroup: ageGroup ?? this.ageGroup,
        cycleLength: cycleLength ?? this.cycleLength,
        symptoms: symptoms ?? this.symptoms,
        goals: goals ?? this.goals,
        pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      );

  /// Returns true if the user has selected at least one valid value
  /// for the given 0-based [step].
  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return ageGroup.isNotEmpty;
      case 1:
        return cycleLength.isNotEmpty;
      case 2:
        return symptoms.isNotEmpty;
      case 3:
        return goals.isNotEmpty;
      case 4:
        return pregnancyStatus.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  List<Object?> get props =>
      [ageGroup, cycleLength, symptoms, goals, pregnancyStatus];
}
