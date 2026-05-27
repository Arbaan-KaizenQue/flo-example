import '../models/cycle_log.dart';
import '../models/json_response.dart';
import '../models/mood_entry.dart';
import '../models/onboarding_answers.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';
import '../services/gemini_service.dart';

abstract class RecommendationRepository {
  bool get hasApiKey;

  Future<JsonResponse> generate({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
  });

  Stream<String> streamFocused({
    required List<String> focusAreas,
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
  });
}

class RecommendationRepositoryImpl implements RecommendationRepository {
  const RecommendationRepositoryImpl({required this.geminiService});

  final GeminiService geminiService;

  @override
  bool get hasApiKey => geminiService.hasApiKey;

  @override
  Future<JsonResponse> generate({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
  }) =>
      geminiService.generateInsights(
        cycles: cycles,
        symptoms: symptoms,
        sleep: sleep,
        water: water,
        mood: mood,
        profile: profile,
      );

  @override
  Stream<String> streamFocused({
    required List<String> focusAreas,
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
  }) =>
      geminiService.streamFocusedInsight(
        focusAreas: focusAreas,
        cycles: cycles,
        symptoms: symptoms,
        sleep: sleep,
        water: water,
        mood: mood,
        profile: profile,
      );
}
