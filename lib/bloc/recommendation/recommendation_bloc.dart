import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/cycle_log.dart';
import '../../data/models/onboarding_answers.dart';
import '../../data/models/recommendation.dart';
import '../../data/models/sleep_log.dart';
import '../../data/models/symptom_entry.dart';
import '../../data/models/water_log.dart';
import '../../data/repositories/cycle_log_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/recommendation_repository.dart';
import '../../data/repositories/sleep_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/water_repository.dart';

part 'recommendation_event.dart';
part 'recommendation_state.dart';

/// [RecommendationBloc] — Style A. Subscribes to every source repo and
/// triggers Gemini calls through [RecommendationRepository].
///
/// Lifecycle:
///   - Source stream emits → cache the slice → fire [_RecomputeRequested]
///   - [_RecomputeRequested] starts a 5-second debounce timer
///   - When the timer elapses, hash the inputs; if the hash is unchanged
///     (or generation already in flight), skip; otherwise call Gemini
///   - [RefreshRecommendations] bypasses the debounce/cache (manual refresh)
class RecommendationBloc
    extends Bloc<RecommendationEvent, RecommendationState> {
  RecommendationBloc({
    required this.recommendationRepository,
    required this.cycleLogRepository,
    required this.symptomRepository,
    required this.sleepRepository,
    required this.waterRepository,
    required this.onboardingRepository,
  }) : super(RecommendationState(
          hasApiKey: recommendationRepository.hasApiKey,
        )) {
    on<WatchRecommendations>(_onWatch);
    on<RefreshRecommendations>(_onRefresh);
    on<_RecomputeRequested>(_onRecomputeRequested);
    on<_GenerationStarted>(_onGenStarted);
    on<_GenerationFinished>(_onGenFinished);
  }

  final RecommendationRepository recommendationRepository;
  final CycleLogRepository cycleLogRepository;
  final SymptomRepository symptomRepository;
  final SleepRepository sleepRepository;
  final WaterRepository waterRepository;
  final OnboardingRepository onboardingRepository;

  static const Duration _debounce = Duration(seconds: 5);

  List<CycleLog> _cycles = const [];
  List<SymptomEntry> _symptoms = const [];
  List<SleepLog> _sleep = const [];
  List<WaterLog> _water = const [];
  OnboardingAnswers _profile = const OnboardingAnswers();

  String? _lastInputHash;
  Timer? _debounceTimer;
  bool _generating = false;

  StreamSubscription<List<CycleLog>>? _cycleSub;
  StreamSubscription<List<SymptomEntry>>? _symptomSub;
  StreamSubscription<List<SleepLog>>? _sleepSub;
  StreamSubscription<List<WaterLog>>? _waterSub;

  // ============================================================
  // Event handlers
  // ============================================================

  FutureOr<void> _onWatch(
      WatchRecommendations event, Emitter<RecommendationState> emit) {
    _profile = onboardingRepository.loadAnswers();

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

    add(const _RecomputeRequested());
  }

  FutureOr<void> _onRefresh(
      RefreshRecommendations event, Emitter<RecommendationState> emit) {
    // Force-regenerate even if input hash hasn't changed.
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

  FutureOr<void> _onGenFinished(
      _GenerationFinished event, Emitter<RecommendationState> emit) {
    if (event.error != null) {
      emit(state.copyWith(isLoading: false, error: event.error!));
    } else {
      emit(state.copyWith(
        isLoading: false,
        recommendations: event.recommendations ?? state.recommendations,
        lastUpdatedAt: DateTime.now(),
        error: '',
      ));
    }
  }

  // ============================================================
  // Generation
  // ============================================================

  void _kickOffGeneration() {
    // Refresh profile (from prefs — no stream).
    _profile = onboardingRepository.loadAnswers();

    if (!recommendationRepository.hasApiKey) {
      // Stay silent — UI handles the empty-state hint.
      return;
    }
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
        profile: _profile,
      );
      if (res.success) {
        _lastInputHash = hash;
        final recs = res.data as List<Recommendation>? ?? const [];
        add(_GenerationFinished(recommendations: recs));
      } else {
        add(_GenerationFinished(error: res.message));
      }
      _generating = false;
    }();
  }

  /// Cheap fingerprint over the data we send to Gemini. Used to skip
  /// duplicate API calls when nothing has changed.
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
    return super.close();
  }
}
