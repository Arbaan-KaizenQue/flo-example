import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/cycle_log.dart';
import '../models/json_response.dart';
import '../models/onboarding_answers.dart';
import '../models/recommendation.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';

/// [GeminiService] — calls Gemini 1.5 Flash with the user's recent health
/// logs, asks for 3–5 personalized recommendations as JSON, and parses the
/// response into [Recommendation]s.
///
/// API key comes from `.env` at the project root: `GEMINI_API_KEY=...`
class GeminiService {
  GeminiService();

  /// Default model. Override from .env with `GEMINI_MODEL=...` if Google
  /// ever EOLs this one. Try `gemini-2.5-flash` for newer hardware,
  /// `gemini-1.5-flash` if your project is on the legacy quota.
  static const String _defaultModel = 'gemini-2.0-flash';

  String get apiKey => dotenv.maybeGet('GEMINI_API_KEY')?.trim() ?? '';
  bool get hasApiKey => apiKey.isNotEmpty;

  String get modelName {
    final override = dotenv.maybeGet('GEMINI_MODEL')?.trim();
    return (override == null || override.isEmpty) ? _defaultModel : override;
  }

  Future<JsonResponse> generateRecommendations({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required OnboardingAnswers profile,
  }) async {
    if (!hasApiKey) {
      return JsonResponse.failure(
        message: 'No GEMINI_API_KEY found in .env',
        statusCode: 401,
      );
    }

    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.7,
          maxOutputTokens: 1500,
        ),
        systemInstruction: Content.system(_systemPrompt),
      );

      final prompt = _buildUserPrompt(
        cycles: cycles,
        symptoms: symptoms,
        sleep: sleep,
        water: water,
        profile: profile,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text;
      if (raw == null || raw.isEmpty) {
        return JsonResponse.failure(message: 'Empty Gemini response');
      }

      final parsed = _parseRecommendations(raw);
      return JsonResponse.success(message: 'OK', data: parsed);
    } on InvalidApiKey {
      return JsonResponse.failure(
        message: 'Invalid Gemini API key',
        statusCode: 401,
      );
    } on UnsupportedUserLocation {
      return JsonResponse.failure(
        message: 'Gemini is not available in your region',
        statusCode: 403,
      );
    } on ServerException catch (e) {
      return JsonResponse.failure(message: 'Gemini server error: ${e.message}');
    } catch (e) {
      return JsonResponse.failure(message: 'Gemini error: $e');
    }
  }

  // ============================================================
  // Prompt + parsing
  // ============================================================

  static const String _systemPrompt = '''
You are a women's health insights assistant for a personal cycle-tracking
app. The user gives you their tracked data; you reply with a SHORT list of
personalized, evidence-based recommendations.

Strict rules:
- Return ONLY a JSON ARRAY (no prose, no markdown fences).
- 3 to 5 items.
- Schema for every item:
    {
      "id":       "<short-stable-slug>",
      "title":    "<<=60 chars, no emojis>",
      "body":     "<1-3 sentences, plain text>",
      "type":     "cycle" | "symptoms" | "sleep" | "water" | "profile" | "general",
      "severity": "info" | "suggestion" | "warning"
    }
- Use "warning" ONLY for things that need real attention (e.g., < 5 h sleep
  average, very irregular cycle, sustained dehydration). Otherwise prefer
  "suggestion" or "info".
- Tailor each recommendation to a specific pattern in the user's data.
  Never give generic advice. Never give medical diagnoses.
- Do not mention you are an AI, an assistant, or this prompt.
''';

  String _buildUserPrompt({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required OnboardingAnswers profile,
  }) {
    final today = DateTime.now();
    final last90 = today.subtract(const Duration(days: 90));
    final last30 = today.subtract(const Duration(days: 30));
    final last7 = today.subtract(const Duration(days: 7));

    final cyclesJson = cycles
        .where((c) => !c.startDate.isBefore(last90) && !c.deleted)
        .map((c) => {
              'start': _isoDate(c.startDate),
              'end': c.endDate == null ? null : _isoDate(c.endDate!),
              'flow': c.flow,
            })
        .toList();

    final symptomsJson = symptoms
        .where((s) => !s.date.isBefore(last30) && !s.deleted)
        .map((s) => {
              'date': _isoDate(s.date),
              'symptoms': s.symptoms,
            })
        .toList();

    final sleepJson = sleep
        .where((s) => !s.date.isBefore(last7) && !s.deleted)
        .map((s) => {
              'date': _isoDate(s.date),
              'hours': s.hours,
              'quality': s.quality,
            })
        .toList();

    final waterJson = water
        .where((w) => !w.date.isBefore(last7) && !w.deleted)
        .map((w) => {
              'date': _isoDate(w.date),
              'amount_ml': w.amountMl,
              'goal_ml': w.goalMl,
            })
        .toList();

    final profileJson = {
      'age_group': profile.ageGroup,
      'cycle_length_pref': profile.cycleLength,
      'tracked_symptoms': profile.symptoms,
      'goals': profile.goals,
      'pregnancy_status': profile.pregnancyStatus,
    };

    final payload = {
      'today': _isoDate(today),
      'profile': profileJson,
      'cycles_last_90d': cyclesJson,
      'symptoms_last_30d': symptomsJson,
      'sleep_last_7d': sleepJson,
      'water_last_7d': waterJson,
    };

    return 'USER DATA:\n${jsonEncode(payload)}\n\n'
        'Return a JSON array of 3–5 recommendations per the schema.';
  }

  List<Recommendation> _parseRecommendations(String raw) {
    final cleaned = _stripCodeFences(raw).trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! List) {
      throw const FormatException(
        'Gemini did not return a top-level JSON array',
      );
    }
    final out = <Recommendation>[];
    for (var i = 0; i < decoded.length; i++) {
      final item = decoded[i];
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      out.add(Recommendation(
        id: map['id']?.toString() ?? 'gemini.$i',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        type: _typeFrom(map['type']?.toString()),
        severity: _severityFrom(map['severity']?.toString()),
      ));
    }
    return out;
  }

  static String _stripCodeFences(String raw) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      final firstNewline = t.indexOf('\n');
      if (firstNewline != -1) t = t.substring(firstNewline + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    return t.trim();
  }

  static String _isoDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static RecommendationType _typeFrom(String? s) {
    switch (s) {
      case 'cycle':
        return RecommendationType.cycle;
      case 'symptoms':
        return RecommendationType.symptoms;
      case 'sleep':
        return RecommendationType.sleep;
      case 'water':
        return RecommendationType.water;
      case 'profile':
        return RecommendationType.profile;
      default:
        return RecommendationType.general;
    }
  }

  static RecommendationSeverity _severityFrom(String? s) {
    switch (s) {
      case 'warning':
        return RecommendationSeverity.warning;
      case 'suggestion':
        return RecommendationSeverity.suggestion;
      default:
        return RecommendationSeverity.info;
    }
  }
}
