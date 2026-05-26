import '../models/cycle_log.dart';
import '../models/json_response.dart';
import '../models/onboarding_answers.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';
import '../services/gemini_service.dart';

abstract class RecommendationRepository {
  bool get hasApiKey;

  /// Returns a [JsonResponse] whose `data` is an [AIInsightsBundle] on
  /// success.
  Future<JsonResponse> generate({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
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
    required OnboardingAnswers profile,
  }) =>
      geminiService.generateInsights(
        cycles: cycles,
        symptoms: symptoms,
        sleep: sleep,
        water: water,
        profile: profile,
      );
}
