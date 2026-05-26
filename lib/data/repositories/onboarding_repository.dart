import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../models/onboarding_answers.dart';

/// [OnboardingRepository] — persists the multi-step onboarding draft and
/// the current step index to [SharedPreferences]. No HydratedBloc.
abstract class OnboardingRepository {
  OnboardingAnswers loadAnswers();
  Future<void> saveAnswers(OnboardingAnswers answers);

  int loadCurrentStep();
  Future<void> saveCurrentStep(int step);

  Future<void> clear();
}

class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl({required this.prefs});

  final SharedPreferences prefs;

  @override
  OnboardingAnswers loadAnswers() {
    final raw = prefs.getString(StorageKeys.onboardingAnswers);
    if (raw == null || raw.isEmpty) return const OnboardingAnswers();
    try {
      return OnboardingAnswers.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const OnboardingAnswers();
    }
  }

  @override
  Future<void> saveAnswers(OnboardingAnswers answers) => prefs.setString(
        StorageKeys.onboardingAnswers,
        jsonEncode(answers.toJson()),
      );

  @override
  int loadCurrentStep() => prefs.getInt(StorageKeys.onboardingStep) ?? 0;

  @override
  Future<void> saveCurrentStep(int step) =>
      prefs.setInt(StorageKeys.onboardingStep, step);

  @override
  Future<void> clear() async {
    await prefs.remove(StorageKeys.onboardingAnswers);
    await prefs.remove(StorageKeys.onboardingStep);
  }
}
