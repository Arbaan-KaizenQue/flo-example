import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/onboarding_answers.dart';
import '../../data/repositories/onboarding_repository.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// [OnboardingBloc] — Style A. Drives the 5-step form.
/// Persists [draft] + [currentStep] to SharedPreferences after every change
/// so users can quit the app and resume from the same place.
///
/// Events:
/// 1) [LoadOnboarding] — hydrate from disk.
/// 2) [UpdateOnboardingAnswers] — replace draft (e.g., chip selection).
/// 3) [GoToOnboardingStep] — change current step (next/back).
/// 4) [SubmitOnboarding] — finalize; UI then marks onboarding complete.
/// 5) [ResetOnboardingState] — wipe draft + step back to 0.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required this.repository}) : super(const OnboardingState()) {
    on<LoadOnboarding>(_onLoad);
    on<UpdateOnboardingAnswers>(_onUpdate);
    on<GoToOnboardingStep>(_onGoToStep);
    on<SubmitOnboarding>(_onSubmit);
    on<ResetOnboardingState>(_onReset);
  }

  final OnboardingRepository repository;

  static const int totalSteps = 5;

  FutureOr<void> _onLoad(
      LoadOnboarding event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      draft: repository.loadAnswers(),
      currentStep: repository.loadCurrentStep(),
    ));
  }

  FutureOr<void> _onUpdate(
      UpdateOnboardingAnswers event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(draft: event.draft));
    await repository.saveAnswers(event.draft);
  }

  FutureOr<void> _onGoToStep(
      GoToOnboardingStep event, Emitter<OnboardingState> emit) async {
    final clamped = event.step.clamp(0, totalSteps - 1);
    emit(state.copyWith(currentStep: clamped));
    await repository.saveCurrentStep(clamped);
  }

  FutureOr<void> _onSubmit(
      SubmitOnboarding event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    await repository.saveAnswers(state.draft);
    await repository.saveCurrentStep(totalSteps - 1);
    emit(state.copyWith(
      isLoading: false,
      isComplete: true,
      message: 'Onboarding complete',
    ));
  }

  FutureOr<void> _onReset(
      ResetOnboardingState event, Emitter<OnboardingState> emit) async {
    await repository.clear();
    emit(const OnboardingState());
  }
}
