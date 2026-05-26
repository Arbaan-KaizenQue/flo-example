part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class LoadOnboarding extends OnboardingEvent {
  const LoadOnboarding();
}

class UpdateOnboardingAnswers extends OnboardingEvent {
  const UpdateOnboardingAnswers({required this.draft});

  final OnboardingAnswers draft;

  @override
  List<Object> get props => [draft];
}

class GoToOnboardingStep extends OnboardingEvent {
  const GoToOnboardingStep({required this.step});

  final int step;

  @override
  List<Object> get props => [step];
}

class SubmitOnboarding extends OnboardingEvent {
  const SubmitOnboarding();
}

class ResetOnboardingState extends OnboardingEvent {
  const ResetOnboardingState();
}
