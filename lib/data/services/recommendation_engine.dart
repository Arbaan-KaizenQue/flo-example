import '../models/cycle_log.dart';
import '../models/onboarding_answers.dart';
import '../models/recommendation.dart';
import '../models/sleep_log.dart';
import '../models/symptom_entry.dart';
import '../models/water_log.dart';

/// [RecommendationEngine] — pure compute. Given the user's recent logs +
/// profile, returns a ranked list of [Recommendation]s for the dashboard.
///
/// Rule-based (no LLM, no network). Replace [generate] with an LLM call
/// later without touching anything else.
class RecommendationEngine {
  RecommendationEngine._();

  /// Days we look back for "recent" data.
  static const int recentWindowDays = 30;

  /// Daily hydration target used when no per-day goal exists.
  static const int defaultDailyWaterMl = 2000;

  /// Luteal phase length used for the on-the-fly ovulation estimate. Keep in
  /// sync with PredictionBloc's default.
  static const int lutealPhaseLength = 14;

  static List<Recommendation> generate({
    required List<CycleLog> cycles,
    required List<SymptomEntry> symptoms,
    required List<SleepLog> sleep,
    required List<WaterLog> water,
    required OnboardingAnswers profile,
    DateTime? now,
  }) {
    final today = _dayOnly(now ?? DateTime.now());
    final windowStart =
        today.subtract(const Duration(days: recentWindowDays));

    final out = <Recommendation>[];

    // ---- Cycle phase ---------------------------------------------------
    final cycleRecs = _cycleRules(cycles, today);
    out.addAll(cycleRecs);

    // ---- Symptoms ------------------------------------------------------
    final recentSymptoms =
        symptoms.where((s) => !s.date.isBefore(windowStart)).toList();
    out.addAll(_symptomRules(recentSymptoms));

    // ---- Sleep ---------------------------------------------------------
    final recentSleep = sleep
        .where((s) =>
            !s.date.isBefore(today.subtract(const Duration(days: 7))))
        .toList();
    out.addAll(_sleepRules(recentSleep));

    // ---- Water ---------------------------------------------------------
    final recentWater = water
        .where((w) =>
            !w.date.isBefore(today.subtract(const Duration(days: 7))))
        .toList();
    out.addAll(_waterRules(recentWater, today));

    // ---- Profile-goal nudges -----------------------------------------
    out.addAll(_profileRules(profile, cycles.isNotEmpty));

    // Rank: warnings first, then suggestions, then info. Cap at 5.
    out.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return out.take(5).toList(growable: false);
  }

  // ============================================================
  // Rule blocks
  // ============================================================

  static List<Recommendation> _cycleRules(
      List<CycleLog> cycles, DateTime today) {
    if (cycles.isEmpty) {
      return const [
        Recommendation(
          id: 'cycle.first_log',
          title: 'Log your first period',
          body: 'Once you log even one cycle we can predict your next '
              'period and fertile window.',
          type: RecommendationType.cycle,
          severity: RecommendationSeverity.suggestion,
        ),
      ];
    }

    final starts = cycles.map((c) => _dayOnly(c.startDate)).toList()..sort();
    final lastStart = starts.last;

    int avg = 28;
    int variance = 0;
    if (starts.length >= 2) {
      final diffs = <int>[];
      for (var i = 1; i < starts.length; i++) {
        diffs.add(starts[i].difference(starts[i - 1]).inDays);
      }
      final valid = diffs.where((d) => d >= 18 && d <= 45).toList();
      if (valid.isNotEmpty) {
        avg = (valid.fold<int>(0, (s, d) => s + d) / valid.length).round();
        final min = valid.reduce((a, b) => a < b ? a : b);
        final max = valid.reduce((a, b) => a > b ? a : b);
        variance = max - min;
      }
    }

    final nextStart = lastStart.add(Duration(days: avg));
    final daysUntil = nextStart.difference(today).inDays;
    final dayOfCycle = today.difference(lastStart).inDays + 1;

    final ovulation = nextStart.subtract(Duration(days: lutealPhaseLength));
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));
    final isFertileToday =
        !today.isBefore(fertileStart) && !today.isAfter(fertileEnd);

    final out = <Recommendation>[];

    if (dayOfCycle == 1) {
      out.add(const Recommendation(
        id: 'cycle.day1',
        title: 'Day 1 of your cycle',
        body: 'Stay hydrated and consider iron-rich foods like spinach, '
            'lentils, and pumpkin seeds.',
        type: RecommendationType.cycle,
        severity: RecommendationSeverity.info,
      ));
    } else if (daysUntil <= 2 && daysUntil >= 0) {
      out.add(Recommendation(
        id: 'cycle.upcoming',
        title: daysUntil == 0
            ? 'Period expected today'
            : 'Period in $daysUntil day${daysUntil == 1 ? '' : 's'}',
        body: 'Keep supplies nearby and slow down where you can.',
        type: RecommendationType.cycle,
        severity: RecommendationSeverity.suggestion,
      ));
    }

    if (isFertileToday) {
      out.add(const Recommendation(
        id: 'cycle.fertile',
        title: "You're in your fertile window",
        body: 'Tracking basal body temperature each morning gives the most '
            'accurate ovulation signal.',
        type: RecommendationType.cycle,
        severity: RecommendationSeverity.suggestion,
      ));
    }

    if (variance >= 7 && starts.length >= 3) {
      out.add(Recommendation(
        id: 'cycle.irregular',
        title: 'Your cycle varies by $variance days',
        body: 'Predictions get more accurate the more periods you log. '
            'Aim to log every period for the next few months.',
        type: RecommendationType.cycle,
        severity: RecommendationSeverity.info,
      ));
    }

    return out;
  }

  static const _symptomTips = <String, String>{
    'Cramps':
        'Magnesium-rich foods (dark chocolate, almonds) and a heat pad can ease cramping.',
    'Headache':
        'Hydrate, ease up on screens, and check if caffeine timing might be a trigger.',
    'Mood swings':
        'Gentle movement and consistent sleep timing tend to even out cycle-related mood shifts.',
    'Fatigue':
        'Iron and B-vitamins help — and protect your sleep first.',
    'Bloating':
        'Cut salt, sip more water through the day, and try light walks after meals.',
    'Acne':
        'Hands off the face and a simple cleanser-moisturizer routine help most.',
    'Tender breasts':
        'Cutting caffeine and wearing a supportive bra both ease tenderness.',
    'Backache':
        'Heat, light stretching, and small posture resets every hour help.',
    'Nausea':
        'Small bland snacks (crackers, ginger) and slow sips of water can settle the stomach.',
    'Cravings':
        'Pair cravings with protein — keeps blood sugar steady so you eat less overall.',
    'Insomnia':
        'A dark cool room and a no-screens hour before bed give the biggest sleep wins.',
  };

  static List<Recommendation> _symptomRules(List<SymptomEntry> recent) {
    if (recent.isEmpty) return const [];

    // Count occurrences across recent entries.
    final counts = <String, int>{};
    for (final e in recent) {
      for (final s in e.symptoms) {
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const [];

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    final tip = _symptomTips[top.key];
    if (tip == null) return const [];

    return [
      Recommendation(
        id: 'symptom.top.${top.key}',
        title: '${top.key} is your most-logged symptom',
        body: tip,
        type: RecommendationType.symptoms,
        severity: RecommendationSeverity.suggestion,
      ),
    ];
  }

  static List<Recommendation> _sleepRules(List<SleepLog> recent) {
    if (recent.isEmpty) return const [];
    final avg = recent.fold<double>(0, (s, l) => s + l.hours) / recent.length;
    if (avg < 6) {
      return [
        Recommendation(
          id: 'sleep.low',
          title: 'Averaging ${avg.toStringAsFixed(1)} h sleep',
          body: 'You\'re below 6 h on average this week. Try moving bedtime '
              '30 min earlier for 3 nights.',
          type: RecommendationType.sleep,
          severity: RecommendationSeverity.warning,
        ),
      ];
    }
    if (avg >= 7 && avg < 9) {
      return [
        Recommendation(
          id: 'sleep.healthy',
          title: 'Sleep is on track',
          body:
              '${avg.toStringAsFixed(1)} h average this week — keep your bedtime steady.',
          type: RecommendationType.sleep,
          severity: RecommendationSeverity.info,
        ),
      ];
    }
    return const [];
  }

  static List<Recommendation> _waterRules(
      List<WaterLog> recent, DateTime today) {
    if (recent.isEmpty) return const [];
    final totalDays = recent.length;
    final totalMl = recent.fold<int>(0, (s, l) => s + l.amountMl);
    final avg = totalMl / totalDays;
    final goal = recent.first.goalMl == 0
        ? defaultDailyWaterMl
        : recent.first.goalMl;

    if (avg < goal * 0.6) {
      return [
        Recommendation(
          id: 'water.low',
          title: 'Hydration is low this week',
          body: 'Averaging ${(avg / 1000).toStringAsFixed(1)} L/day '
              '(goal ${(goal / 1000).toStringAsFixed(1)} L). '
              'Keep a bottle in sight.',
          type: RecommendationType.water,
          severity: RecommendationSeverity.warning,
        ),
      ];
    }

    return const [];
  }

  static List<Recommendation> _profileRules(
      OnboardingAnswers profile, bool hasCycleHistory) {
    final out = <Recommendation>[];

    if (profile.goals.contains('Plan pregnancy') && !hasCycleHistory) {
      out.add(const Recommendation(
        id: 'profile.preg.no_history',
        title: 'Start logging to plan',
        body: 'Logging just 2–3 cycles will give a reliable fertile-window '
            'estimate.',
        type: RecommendationType.profile,
        severity: RecommendationSeverity.suggestion,
      ));
    }

    if (profile.symptoms.isNotEmpty) {
      out.add(Recommendation(
        id: 'profile.symptoms.track',
        title: 'You said you wanted to track symptoms',
        body: 'Log each day you feel one of: '
            '${profile.symptoms.take(3).join(', ')}. '
            'Patterns show up after ~2 cycles of data.',
        type: RecommendationType.profile,
        severity: RecommendationSeverity.info,
      ));
    }

    return out;
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
