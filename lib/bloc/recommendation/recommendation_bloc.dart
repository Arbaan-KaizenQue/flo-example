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
import '../../data/repositories/sleep_repository.dart';
import '../../data/repositories/symptom_repository.dart';
import '../../data/repositories/water_repository.dart';
import '../../data/services/recommendation_engine.dart';

part 'recommendation_event.dart';
part 'recommendation_state.dart';

/// [RecommendationBloc] — Style A. Subscribes to every data source the
/// [RecommendationEngine] needs, caches the latest slice of each, and
/// re-runs the engine on every update.
class RecommendationBloc
    extends Bloc<RecommendationEvent, RecommendationState> {
  RecommendationBloc({
    required this.cycleLogRepository,
    required this.symptomRepository,
    required this.sleepRepository,
    required this.waterRepository,
    required this.onboardingRepository,
  }) : super(const RecommendationState()) {
    on<WatchRecommendations>(_onWatch);
    on<_RecomputeRecommendations>(_onRecompute);
  }

  final CycleLogRepository cycleLogRepository;
  final SymptomRepository symptomRepository;
  final SleepRepository sleepRepository;
  final WaterRepository waterRepository;
  final OnboardingRepository onboardingRepository;

  List<CycleLog> _cycles = const [];
  List<SymptomEntry> _symptoms = const [];
  List<SleepLog> _sleep = const [];
  List<WaterLog> _water = const [];
  OnboardingAnswers _profile = const OnboardingAnswers();

  StreamSubscription<List<CycleLog>>? _cycleSub;
  StreamSubscription<List<SymptomEntry>>? _symptomSub;
  StreamSubscription<List<SleepLog>>? _sleepSub;
  StreamSubscription<List<WaterLog>>? _waterSub;

  FutureOr<void> _onWatch(
      WatchRecommendations event, Emitter<RecommendationState> emit) {
    // Onboarding answers come from SharedPreferences — no stream needed;
    // re-read whenever something else changes.
    _profile = onboardingRepository.loadAnswers();

    _cycleSub?.cancel();
    _cycleSub = cycleLogRepository.watchAll().listen((logs) {
      _cycles = logs;
      add(const _RecomputeRecommendations());
    });
    _symptomSub?.cancel();
    _symptomSub = symptomRepository.watchAll().listen((entries) {
      _symptoms = entries;
      add(const _RecomputeRecommendations());
    });
    _sleepSub?.cancel();
    _sleepSub = sleepRepository.watchAll().listen((logs) {
      _sleep = logs;
      add(const _RecomputeRecommendations());
    });
    _waterSub?.cancel();
    _waterSub = waterRepository.watchAll().listen((logs) {
      _water = logs;
      add(const _RecomputeRecommendations());
    });

    add(const _RecomputeRecommendations());
  }

  FutureOr<void> _onRecompute(
      _RecomputeRecommendations event, Emitter<RecommendationState> emit) {
    // Refresh profile on every recompute so dashboard reflects any
    // onboarding edits the user has made.
    _profile = onboardingRepository.loadAnswers();
    final recs = RecommendationEngine.generate(
      cycles: _cycles,
      symptoms: _symptoms,
      sleep: _sleep,
      water: _water,
      profile: _profile,
    );
    emit(state.copyWith(isLoading: false, recommendations: recs));
  }

  @override
  Future<void> close() {
    _cycleSub?.cancel();
    _symptomSub?.cancel();
    _sleepSub?.cancel();
    _waterSub?.cancel();
    return super.close();
  }
}
