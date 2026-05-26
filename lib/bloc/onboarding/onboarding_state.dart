part of 'onboarding_bloc.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.draft = const OnboardingAnswers(),
    this.currentStep = 0,
    this.isComplete = false,
  });

  final bool isLoading;
  final String error;
  final String message;
  final OnboardingAnswers draft;
  final int currentStep;
  final bool isComplete;

  OnboardingState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    OnboardingAnswers? draft,
    int? currentStep,
    bool? isComplete,
  }) =>
      OnboardingState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        draft: draft ?? this.draft,
        currentStep: currentStep ?? this.currentStep,
        isComplete: isComplete ?? this.isComplete,
      );

  @override
  List<Object?> get props =>
      [isLoading, error, message, draft, currentStep, isComplete];
}
