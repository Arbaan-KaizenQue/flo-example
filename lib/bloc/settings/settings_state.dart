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
    this.pregnancyModeEnabled = false,
    this.pregnancyLmp,
  });

  final bool isLoading;
  final String error;
  final String message;
  final bool acceptedTerms;
  final bool driveEnabled;
  final bool onboardingComplete;
  final DateTime? lastSyncedAt;

  // Feature 20
  final bool pregnancyModeEnabled;
  final DateTime? pregnancyLmp;

  /// Derived pregnancy info — null when mode is off or no LMP set.
  PregnancyContext? get pregnancyContext {
    if (!pregnancyModeEnabled || pregnancyLmp == null) return null;
    return PregnancyContext.fromLmp(pregnancyLmp!);
  }

  SettingsState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool? acceptedTerms,
    bool? driveEnabled,
    bool? onboardingComplete,
    DateTime? lastSyncedAt,
    bool? pregnancyModeEnabled,
    DateTime? pregnancyLmp,
    bool clearPregnancyLmp = false,
  }) =>
      SettingsState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        message: message ?? this.message,
        acceptedTerms: acceptedTerms ?? this.acceptedTerms,
        driveEnabled: driveEnabled ?? this.driveEnabled,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        pregnancyModeEnabled:
            pregnancyModeEnabled ?? this.pregnancyModeEnabled,
        pregnancyLmp:
            clearPregnancyLmp ? null : (pregnancyLmp ?? this.pregnancyLmp),
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
        pregnancyModeEnabled,
        pregnancyLmp,
      ];
}
