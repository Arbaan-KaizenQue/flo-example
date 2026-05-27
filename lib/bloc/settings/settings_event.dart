part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class RefreshSettings extends SettingsEvent {
  const RefreshSettings();
}

class AcceptTerms extends SettingsEvent {
  const AcceptTerms();
}

class ToggleDriveEnabled extends SettingsEvent {
  const ToggleDriveEnabled({required this.enabled});

  final bool enabled;

  @override
  List<Object> get props => [enabled];
}

class SyncNowFromSettings extends SettingsEvent {
  const SyncNowFromSettings();
}

class SignOutFromSettings extends SettingsEvent {
  const SignOutFromSettings();
}

class DeleteCloudBackup extends SettingsEvent {
  const DeleteCloudBackup();
}

class MarkOnboardingComplete extends SettingsEvent {
  const MarkOnboardingComplete();
}

class ResetOnboarding extends SettingsEvent {
  const ResetOnboarding();
}

// Feature 20 — Pregnancy Mode
class TogglePregnancyMode extends SettingsEvent {
  const TogglePregnancyMode({required this.enabled, this.lmp});

  final bool enabled;

  /// Required when enabling — the LMP date.
  final DateTime? lmp;

  @override
  List<Object?> get props => [enabled, lmp];
}

class SetPregnancyLmp extends SettingsEvent {
  const SetPregnancyLmp({required this.lmp});

  final DateTime lmp;

  @override
  List<Object> get props => [lmp];
}
