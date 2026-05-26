part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.isLoading = false,
    this.error = '',
    this.message = '',
    this.acceptedTerms = false,
    this.driveEnabled = false,
    this.onboardingComplete = false,
    this.lastSyncedAt,
  });

  final bool isLoading;
  final String error;
  final String message;
  final bool acceptedTerms;
  final bool driveEnabled;
  final bool onboardingComplete;
  final DateTime? lastSyncedAt;

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool? acceptedTerms,
    bool? driveEnabled,
    bool? onboardingComplete,
    DateTime? lastSyncedAt,
  }) =>
      SettingsState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        acceptedTerms: acceptedTerms ?? this.acceptedTerms,
        driveEnabled: driveEnabled ?? this.driveEnabled,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );

  @override
  List<Object?> get props => [
        isLoading,
        error,
        message,
        acceptedTerms,
        driveEnabled,
        onboardingComplete,
        lastSyncedAt,
      ];
}
