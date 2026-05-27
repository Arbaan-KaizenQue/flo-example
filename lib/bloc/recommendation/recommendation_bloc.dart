import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/cycle_log.dart';
import '../../data/models/mood_entry.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/models/recommendation.dart';
import '../../data/models/sleep_log.dart';
import '../../data/models/symptom_entry.dart';
import '../../data/models/water_log.dart';
import '../../data/repositories/ai_insight_repository.dart';
import '../../data/repositories/cycle_log_repository.dart';
import '../../data/repositories/mood_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../data/repositories/sleep_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/services/gemini_service.dart';

part 'recommendation_event.dart';
part 'recommendation_state.dart';

/// [RecommendationBloc] — owns the AI insights for the dashboard.
///
/// Sources:
///   * 4 stream repos (cycle/symptoms/sleep/water) → debounced regen on change
///   * onboarding profile (re-read from prefs on every recompute)
///   * AIInsightRepository → loaded once on init so offline users see stale
///     insights instead of an empty section
class RecommendationBloc
    extends Bloc<RecommendationEvent, RecommendationState> {
  RecommendationBloc({
    required this.recommendationRepository,
    required this.aiInsightRepository,
    required this.cycleLogRepository,
    required this.symptomRepository,
    required this.sleepRepository,
    required this.waterRepository,
    required this.moodRepository,
    required this.onboardingRepository,
  }) : super(RecommendationState(
          hasApiKey: recommendationRepository.hasApiKey,
        )) {
    on<WatchRecommendations>(_onWatch);
    on<RefreshRecommendations>(_onRefresh);
    on<_RecomputeRequested>(_onRecomputeRequested);
    on<_StoredInsightsLoaded>(_onStoredLoaded);
    on<_GenerationStarted>(_onGenStarted);
    on<_GenerationFinished>(_onGenFinished);
  }

  final RecommendationRepository recommendationRepository;
  final AIInsightRepository aiInsightRepository;
  final CycleLogRepository cycleLogRepository;
  final SymptomRepository symptomRepository;
  final SleepRepository sleepRepository;
  final WaterRepository waterRepository;
  final MoodRepository moodRepository;
  final OnboardingRepository onboardingRepository;

  static const Duration _debounce = Duration(seconds: 5);

  List<CycleLog> _cycles = const [];
  List<SymptomEntry> _symptoms = const [];
  List<SleepLog> _sleep = const [];
  List<WaterLog> _water = const [];
  List<MoodEntry> _mood = const [];
  OnboardingAnswers _profile = const OnboardingAnswers();

  String? _lastInputHash;
  Timer? _debounceTimer;
  bool _generating = false;

  StreamSubscription<List<CycleLog>>? _cycleSub;
  StreamSubscription<List<SymptomEntry>>? _symptomSub;
  StreamSubscription<List<SleepLog>>? _sleepSub;
  StreamSubscription<List<WaterLog>>? _waterSub;
  StreamSubscription<List<MoodEntry>>? _moodSub;
  StreamSubscription<List<Recommendation>>? _storedSub;

  // ============================================================
  // Event handlers
  // ============================================================

  FutureOr<void> _onWatch(
      WatchRecommendations event, Emitter<RecommendationState> emit) {
    _profile = onboardingRepository.loadAnswers();

    // Hydrate from disk so offline users see something immediately.
    _storedSub?.cancel();
    _storedSub = aiInsightRepository.watchAll().listen((stored) {
      add(_StoredInsightsLoaded(insights: stored));
    });

    _cycleSub?.cancel();
    _cycleSub = cycleLogRepository.watchAll().listen((logs) {
      _cycles = logs;
      add(const _RecomputeRequested());
    });
    _symptomSub?.cancel();
    _symptomSub = symptomRepository.watchAll().listen((entries) {
      _symptoms = entries;
      add(const _RecomputeRequested());
    });
    _sleepSub?.cancel();
    _sleepSub = sleepRepository.watchAll().listen((logs) {
      _sleep = logs;
      add(const _RecomputeRequested());
    });
    _waterSub?.cancel();
    _waterSub = waterRepository.watchAll().listen((logs) {
      _water = logs;
      add(const _RecomputeRequested());
    });
    _moodSub?.cancel();
    _moodSub = moodRepository.watchAll().listen((entries) {
      _mood = entries;
      add(const _RecomputeRequested());
    });

    add(const _RecomputeRequested());
  }

  FutureOr<void> _onStoredLoaded(
      _StoredInsightsLoaded event, Emitter<RecommendationState> emit) {
    // Only seed state when we don't already have fresher (in-memory) recs.
    if (state.recommendations.isEmpty && event.insights.isNotEmpty) {
      emit(state.copyWith(
        recommendations: event.insights,
        lastUpdatedAt: event.insights.first.createdAt,
      ));
    }
  }

  FutureOr<void> _onRefresh(
      RefreshRecommendations event, Emitter<RecommendationState> emit) {
    _lastInputHash = null;
    _debounceTimer?.cancel();
    _kickOffGeneration();
  }

  FutureOr<void> _onRecomputeRequested(
      _RecomputeRequested event, Emitter<RecommendationState> emit) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, _kickOffGeneration);
  }

  FutureOr<void> _onGenStarted(
      _GenerationStarted event, Emitter<RecommendationState> emit) {
    emit(state.copyWith(isLoading: true, error: ''));
  }

  /// Exposed for the Ask-AI dialog. Returns a token-by-token stream of the
  /// AI's prose reply. Does NOT touch state.recommendations or persist —
  /// the dialog owns the response lifecycle.
  Stream<String> streamFocusedInsight(List<String> focusAreas) {
    _profile = onboardingRepository.loadAnswers();
    return recommendationRepository.streamFocused(
      focusAreas: focusAreas,
      cycles: _cycles,
      symptoms: _symptoms,
      sleep: _sleep,
      water: _water,
      mood: _mood,
      profile: _profile,
    );
  }

  FutureOr<void> _onGenFinished(
      _GenerationFinished event, Emitter<RecommendationState> emit) {
    if (event.error != null) {
      emit(state.copyWith(isLoading: false, error: event.error!));
    } else {
      emit(state.copyWith(
        isLoading: false,
        recommendations: event.insights ?? state.recommendations,
        wellnessScore: event.wellnessScore,
        lastUpdatedAt: DateTime.now(),
        error: '',
      ));
    }
  }

  // ============================================================
  // Generation
  // ============================================================

  void _kickOffGeneration() {
    _profile = onboardingRepository.loadAnswers();

    if (!recommendationRepository.hasApiKey) return;
    if (_generating) return;

    final hash = _computeHash();
    if (_lastInputHash == hash && state.recommendations.isNotEmpty) {
      return; // cached
    }

    _generating = true;
    add(const _GenerationStarted());
    () async {
      final res = await recommendationRepository.generate(
        cycles: _cycles,
        symptoms: _symptoms,
        sleep: _sleep,
        water: _water,
        mood: _mood,
        profile: _profile,
      );
      if (res.success) {
        _lastInputHash = hash;
        final bundle = res.data as AIInsightsBundle?;
        final insights = bundle?.insights ?? const <Recommendation>[];
        // Persist newest insights so they survive a restart / offline boot.
        if (insights.isNotEmpty) {
          unawaited(aiInsightRepository.saveMany(insights));
        }
        add(_GenerationFinished(
          insights: insights,
          wellnessScore: bundle?.wellnessScore,
        ));
      } else {
        add(_GenerationFinished(error: res.message));
      }
      _generating = false;
    }();
  }

  /// Cheap fingerprint over the data we send to Gemini.
  String _computeHash() {
    final parts = <Object?>[
      _cycles.length,
      for (final c in _cycles) ...[c.id, c.updatedAt.millisecondsSinceEpoch],
      _symptoms.length,
      for (final s in _symptoms) ...[s.id, s.updatedAt.millisecondsSinceEpoch],
      _sleep.length,
      for (final s in _sleep) ...[s.id, s.updatedAt.millisecondsSinceEpoch],
      _water.length,
      for (final w in _water) ...[w.id, w.updatedAt.millisecondsSinceEpoch],
      _mood.length,
      for (final m in _mood) ...[m.id, m.updatedAt.millisecondsSinceEpoch],
      _profile.toJson().toString(),
    ];
    return parts.join('|').hashCode.toString();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _cycleSub?.cancel();
    _symptomSub?.cancel();
    _sleepSub?.cancel();
    _waterSub?.cancel();
    _moodSub?.cancel();
    _storedSub?.cancel();
    return super.close();
  }
}
