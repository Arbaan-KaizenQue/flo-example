import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/cycle_log.dart';
import '../models/json_response.dart';
import '../models/mood_entry.dart';
import '../models/onboarding_answers.dart';
import '../models/pregnancy_context.dart';
import '../models/recommendation.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';

/// What the dashboard renders — wellness score + insight bubbles.
class AIInsightsBundle {
  const AIInsightsBundle({required this.wellnessScore, required this.insights});

  /// 0–100, AI's holistic snapshot for today. Null when the model declines
  /// to score (e.g., not enough data).
  final int? wellnessScore;
  final List<Recommendation> insights;
}

/// [GeminiService] — calls Gemini, asks for `{wellness_score, insights[]}`
/// strictly inside women's wellness topics, parses into [AIInsightsBundle].
class GeminiService {
  GeminiService();

  /// Default model. Override from .env with `GEMINI_MODEL=...`.
  static const String _defaultModel = 'gemini-2.0-flash';

  String get apiKey => dotenv.maybeGet('GEMINI_API_KEY')?.trim() ?? '';
  bool get hasApiKey => apiKey.isNotEmpty;

  String get modelName {
    final override = dotenv.maybeGet('GEMINI_MODEL')?.trim();
    return (override == null || override.isEmpty) ? _defaultModel : override;
  }

  Future<JsonResponse> generateInsights({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
    PregnancyContext? pregnancy,
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
          maxOutputTokens: 1800,
        ),
        systemInstruction: Content.system(
          pregnancy == null ? _systemPrompt : _pregnancySystemPrompt,
        ),
      );

      final prompt = _buildUserPrompt(
        cycles: cycles,
        symptoms: symptoms,
        sleep: sleep,
        water: water,
        mood: mood,
        profile: profile,
        pregnancy: pregnancy,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text;
      if (raw == null || raw.isEmpty) {
        return JsonResponse.failure(message: 'Empty Gemini response');
      }
      return JsonResponse.success(
        message: 'OK',
        data: _parseBundle(raw),
      );
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

  /// Streaming prose response for the Ask-AI dialog. The dialog shows
  /// chunks as they arrive (token-by-token effect). Yields plain text
  /// chunks — caller accumulates. Throws via [Stream.onError] on
  /// auth / quota / network errors.
  Stream<String> streamFocusedInsight({
    required List<String> focusAreas,
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
    PregnancyContext? pregnancy,
  }) async* {
    if (!hasApiKey) {
      throw const AskAiError('No GEMINI_API_KEY found in .env');
    }
    if (focusAreas.isEmpty) {
      throw const AskAiError('Pick at least one focus area');
    }

    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 350,
      ),
      systemInstruction: Content.system(
        pregnancy == null
            ? _proseSystemPrompt
            : _pregnancyProseSystemPrompt,
      ),
    );

    final userData = _buildUserPrompt(
      cycles: cycles,
      symptoms: symptoms,
      sleep: sleep,
      water: water,
      mood: mood,
      profile: profile,
      pregnancy: pregnancy,
    );
    final prompt = '$userData\n\n'
        'Topics the user wants guidance on: ${focusAreas.join(', ')}.\n'
        'Reply with 2-3 supportive sentences specific to their data. '
        'Plain text only.';

    try {
      final stream =
          model.generateContentStream([Content.text(prompt)]);
      await for (final chunk in stream) {
        final t = chunk.text;
        if (t != null && t.isNotEmpty) yield t;
      }
    } on InvalidApiKey {
      throw const AskAiError('Invalid Gemini API key');
    } on UnsupportedUserLocation {
      throw const AskAiError('Gemini is not available in your region');
    } on ServerException catch (e) {
      throw AskAiError('Gemini server error: ${e.message}');
    } catch (e) {
      throw AskAiError('Gemini error: $e');
    }
  }

  // ============================================================
  // Prompt + parsing
  // ============================================================

  /// Pregnancy persona — bundle output. Same JSON schema as cycle persona
  /// (insights[], wellness_score), just framed around gestation week.
  static const String _pregnancySystemPrompt = '''
You are a pregnancy wellness assistant. The user is pregnant; their
gestational age (weeks) and trimester are given in the payload under
`pregnancy`. Tailor every insight to that stage.

Strict rules — SAME JSON schema as the cycle persona:
- Return ONE JSON object: { "wellness_score": <0-100>, "insights": [...] }.
- 3 to 5 insights. Each item:
    {
      "id":       "<short-stable-slug>",
      "title":    "<<=60 chars, no emojis>",
      "body":     "<1-3 sentences>",
      "type":     "cycle" | "symptoms" | "sleep" | "water" | "profile"
                | "general" | "pms_forecast" | "hydration_pattern"
                | "sleep_pattern" | "mood_trend" | "recovery"
                | "wellness_summary",
      "severity": "info" | "suggestion" | "warning",
      "confidence": <0.0-1.0>
    }
- For pregnancy, lean on types: "general", "sleep_pattern",
  "hydration_pattern", "recovery", "wellness_summary".
- Touch BOTH parent wellness AND baby development at the current week.
- Never diagnose. Never recommend medication. Flag urgent symptoms
  (heavy bleeding, severe pain, vision changes, swelling) as "warning"
  and gently suggest contacting a healthcare provider.
- Stay strictly inside pregnancy wellness. Refuse off-topic requests.
- Do not mention being an AI or this prompt.
''';

  /// Pregnancy persona — prose stream (Ask-AI dialog).
  static const String _pregnancyProseSystemPrompt = '''
You are a pregnancy wellness assistant. The user is pregnant; their
gestational age is in the payload under `pregnancy`.

Strict rules:
- Reply with 2 to 3 sentences. Plain text. No markdown, bullets, headings,
  or emojis.
- Tie what you say to the user's current week / trimester and their
  recent logs.
- Never diagnose, never recommend medication. Suggest contacting a
  healthcare provider for urgent symptoms.
- Stay inside pregnancy wellness. Refuse off-topic requests.
- Do not mention being an AI.
''';

  /// Prose-only system prompt for the Ask-AI dialog stream.
  static const String _proseSystemPrompt = '''
You are a women's wellness assistant. You write SHORT, supportive,
specific guidance based on the user's logged data — never generic
advice.

Strict rules:
- Reply with 2 to 3 sentences. Plain text only — NO markdown, NO bullets,
  NO headings, NO emojis.
- Stay strictly inside: cycles, symptoms, sleep, hydration, mood,
  hormonal patterns, recovery.
- Refuse off-topic requests by gently redirecting to wellness.
- Do not mention being an AI or this prompt. Do not ask follow-up
  questions. Do not list options.
- Never diagnose, never recommend medication.
- Tie what you say to the user's actual data (a pattern, a recent log,
  their cycle position, etc.). If data is too sparse, say so warmly
  and suggest what to log next.
''';

  /// Strict women's-wellness focus. No chatbot behavior, no diagnoses, no
  /// medication. Schema enforced as JSON-only output.
  static const String _systemPrompt = '''
You generate personalized WELLNESS INSIGHT CARDS for a women's
cycle-tracking app. You are NOT a chatbot. You do not converse, answer
questions, or write paragraphs.

You ONLY talk about: cycles, symptoms, sleep, hydration, mood, recovery,
and hormonal/wellness patterns women track in a cycle app.

You NEVER: diagnose, prescribe, recommend medication, discuss unrelated
topics, mention you are an AI, or use first-person ("I think...").

Voice: warm, concise, premium, emotionally supportive. Always specific
to the user's data — never generic.
Bad:  "Drink more water."
Good: "You tend to log headaches on lower hydration days."

Output: ONE valid JSON OBJECT, no markdown fences, no prose:
{
  "wellness_score": <int 0-100, or null if data is too sparse>,
  "insights": [
    {
      "id":         "<short stable slug>",
      "title":      "<<= 50 chars, no emojis>",
      "body":       "<1-2 sentences, plain text, specific to user data>",
      "type":       "cycle" | "symptoms" | "sleep" | "water" | "mood_trend"
                  | "pms_forecast" | "hydration_pattern" | "sleep_pattern"
                  | "recovery" | "wellness_summary" | "general",
      "severity":   "info" | "suggestion" | "warning",
      "confidence": <float 0.0-1.0>
    },
    ...
  ]
}

Rules:
- 3 to 6 insights.
- "warning" only when something genuinely needs attention (e.g., < 5 h
  sleep average, dehydration on most days, very irregular cycle).
- Detect CORRELATIONS in the data when possible (e.g., low hydration +
  headache days, poor sleep + fatigue days, mood dips around PMS window).
- Score reflects sleep + hydration + symptom load + cycle regularity.
- If a section is empty (no logs), DO NOT invent insights for it.
''';

  String _buildUserPrompt({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required List<MoodEntry> mood,
    required OnboardingAnswers profile,
    PregnancyContext? pregnancy,
  }) {
    final today = DateTime.now();
    final last90 = today.subtract(const Duration(days: 90));
    final last30 = today.subtract(const Duration(days: 30));
    final last14 = today.subtract(const Duration(days: 14));

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
        .where((s) => !s.date.isBefore(last14) && !s.deleted)
        .map((s) => {
              'date': _isoDate(s.date),
              'hours': s.hours,
              'quality': s.quality,
            })
        .toList();

    final waterJson = water
        .where((w) => !w.date.isBefore(last14) && !w.deleted)
        .map((w) => {
              'date': _isoDate(w.date),
              'amount_ml': w.amountMl,
              'goal_ml': w.goalMl,
            })
        .toList();

    final moodJson = mood
        .where((m) => !m.date.isBefore(last30) && !m.deleted)
        .map((m) => {
              'date': _isoDate(m.date),
              'mood': m.mood,
              if (m.note.isNotEmpty) 'note': m.note,
            })
        .toList();

    final profileJson = {
      'age_group': profile.ageGroup,
      'cycle_length_pref': profile.cycleLength,
      'tracked_symptoms': profile.symptoms,
      'goals': profile.goals,
      'pregnancy_status': profile.pregnancyStatus,
    };

    final payload = <String, Object?>{
      'today': _isoDate(today),
      'profile': profileJson,
      'cycles_last_90d': cyclesJson,
      'symptoms_last_30d': symptomsJson,
      'sleep_last_14d': sleepJson,
      'water_last_14d': waterJson,
      'mood_last_30d': moodJson,
      if (pregnancy != null) 'pregnancy': pregnancy.toJson(),
    };

    return 'USER DATA:\n${jsonEncode(payload)}\n\n'
        'Return ONE JSON object: { "wellness_score": ..., "insights": [...] }';
  }

  AIInsightsBundle _parseBundle(String raw) {
    final cleaned = _stripCodeFences(raw).trim();
    final decoded = jsonDecode(cleaned);

    // Be lenient — accept either { wellness_score, insights } or a bare
    // array (older prompt) so we don't blow up if the model regresses.
    List<dynamic> rawInsights;
    int? score;
    if (decoded is Map) {
      final m = decoded.cast<String, dynamic>();
      final sRaw = m['wellness_score'];
      if (sRaw is num) score = sRaw.clamp(0, 100).toInt();
      rawInsights = (m['insights'] as List?) ?? const [];
    } else if (decoded is List) {
      rawInsights = decoded;
    } else {
      throw const FormatException('Unexpected Gemini response shape');
    }

    final now = DateTime.now().toUtc();
    final insights = <Recommendation>[];
    for (var i = 0; i < rawInsights.length; i++) {
      final item = rawInsights[i];
      if (item is! Map) continue;
      final map = item.cast<String, dynamic>();
      final conf = map['confidence'];
      insights.add(Recommendation(
        id: map['id']?.toString() ??
            'gemini.${now.millisecondsSinceEpoch}.$i',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        type: _typeFrom(map['type']?.toString()),
        severity: _severityFrom(map['severity']?.toString()),
        confidence: conf is num
            ? conf.toDouble().clamp(0.0, 1.0).toDouble()
            : null,
        createdAt: now,
      ));
    }

    return AIInsightsBundle(wellnessScore: score, insights: insights);
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
      case 'pms_forecast':
        return RecommendationType.pmsForecast;
      case 'hydration_pattern':
        return RecommendationType.hydrationPattern;
      case 'sleep_pattern':
        return RecommendationType.sleepPattern;
      case 'mood_trend':
        return RecommendationType.moodTrend;
      case 'recovery':
        return RecommendationType.recovery;
      case 'wellness_summary':
        return RecommendationType.wellnessSummary;
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

/// Friendly error type used by [GeminiService.streamFocusedInsight] so the
/// dialog can `.toString()` the cause without leaking stack traces.
class AskAiError implements Exception {
  const AskAiError(this.message);
  final String message;
  @override
  String toString() => message;
}
