import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/pregnancy_context.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/drive_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/settings_repository.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// [SettingsBloc] — Style A. Holds all SharedPreferences-backed flags
/// (`acceptedTerms`, `onboardingComplete`, `driveEnabled`, `lastSyncedAt`)
/// plus the busy/error/message bookkeeping for the settings UI.
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({
    required this.settingsRepository,
    required this.authRepository,
    required this.driveRepository,
    required this.onboardingRepository,
  }) : super(SettingsState(
          welcomeSeen: settingsRepository.welcomeSeen,
          acceptedTerms: settingsRepository.acceptedTerms,
          driveEnabled: settingsRepository.driveEnabled,
          onboardingComplete: settingsRepository.onboardingComplete,
          lastSyncedAt: settingsRepository.lastSyncedAt,
          pregnancyModeEnabled: settingsRepository.pregnancyModeEnabled,
          pregnancyLmp: settingsRepository.pregnancyLmp,
        )) {
    on<RefreshSettings>(_onRefresh);
    on<MarkWelcomeSeen>(_onMarkWelcomeSeen);
    on<AcceptTerms>(_onAcceptTerms);
    on<ToggleDriveEnabled>(_onToggleDrive);
    on<SyncNowFromSettings>(_onSyncNow);
    on<SignOutFromSettings>(_onSignOut);
    on<DeleteCloudBackup>(_onDeleteBackup);
    on<MarkOnboardingComplete>(_onMarkOnboarded);
    on<ResetOnboarding>(_onResetOnboarding);
    on<TogglePregnancyMode>(_onTogglePregnancy);
    on<SetPregnancyLmp>(_onSetLmp);
  }

  final SettingsRepository settingsRepository;
  final AuthRepository authRepository;
  final DriveRepository driveRepository;
  final OnboardingRepository onboardingRepository;

  FutureOr<void> _onRefresh(
      RefreshSettings event, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      isLoading: false,
      acceptedTerms: settingsRepository.acceptedTerms,
      driveEnabled: settingsRepository.driveEnabled,
      onboardingComplete: settingsRepository.onboardingComplete,
      lastSyncedAt: settingsRepository.lastSyncedAt,
      error: '',
    ));
  }

  FutureOr<void> _onMarkWelcomeSeen(
      MarkWelcomeSeen event, Emitter<SettingsState> emit) async {
    await settingsRepository.setWelcomeSeen(true);
    emit(state.copyWith(welcomeSeen: true));
  }

  FutureOr<void> _onAcceptTerms(
      AcceptTerms event, Emitter<SettingsState> emit) async {
    await settingsRepository.setAcceptedTerms(true);
    emit(state.copyWith(acceptedTerms: true));
  }

  FutureOr<void> _onToggleDrive(
      ToggleDriveEnabled event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    try {
      if (event.enabled) {
        if (!driveRepository.isSignedIn) {
          final signIn = await authRepository.signIn();
          if (!signIn.success) {
            emit(state.copyWith(isLoading: false, error: signIn.message));
            return;
          }
        }
        await settingsRepository.setDriveEnabled(true);
        final syncRes = await driveRepository.performSync();
        emit(state.copyWith(
          isLoading: false,
          driveEnabled: true,
          lastSyncedAt: settingsRepository.lastSyncedAt,
          message: syncRes.success ? 'Backup enabled' : '',
          error: syncRes.success ? '' : syncRes.message,
        ));
      } else {
        await settingsRepository.setDriveEnabled(false);
        emit(state.copyWith(
          isLoading: false,
          driveEnabled: false,
          message: 'Backup disabled',
        ));
      }
    } catch (err) {
      emit(state.copyWith(isLoading: false, error: '$err'));
    }
  }

  FutureOr<void> _onSyncNow(
      SyncNowFromSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    final res = await driveRepository.performSync();
    emit(state.copyWith(
      isLoading: false,
      lastSyncedAt: settingsRepository.lastSyncedAt,
      message: res.success ? 'Synced' : '',
      error: res.success ? '' : res.message,
    ));
  }

  FutureOr<void> _onSignOut(
      SignOutFromSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    await authRepository.signOut();
    emit(state.copyWith(
      isLoading: false,
      driveEnabled: false,
      message: 'Signed out',
    ));
  }

  FutureOr<void> _onDeleteBackup(
      DeleteCloudBackup event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true, error: '', message: ''));
    final res = await driveRepository.deleteCloudBackup();
    emit(state.copyWith(
      isLoading: false,
      lastSyncedAt: null,
      message: res.success ? 'Cloud backup deleted' : '',
      error: res.success ? '' : res.message,
    ));
  }

  FutureOr<void> _onMarkOnboarded(
      MarkOnboardingComplete event, Emitter<SettingsState> emit) async {
    await settingsRepository.setOnboardingComplete(true);
    emit(state.copyWith(onboardingComplete: true));
  }

  FutureOr<void> _onResetOnboarding(
      ResetOnboarding event, Emitter<SettingsState> emit) async {
    await settingsRepository.setOnboardingComplete(false);
    await onboardingRepository.clear();
    emit(state.copyWith(onboardingComplete: false, message: 'Onboarding reset'));
  }

  // ============================================================
  // Pregnancy Mode
  // ============================================================

  FutureOr<void> _onTogglePregnancy(
      TogglePregnancyMode event, Emitter<SettingsState> emit) async {
    if (event.enabled) {
      if (event.lmp == null) {
        emit(state.copyWith(error: 'Pick your last period start date'));
        return;
      }
      await settingsRepository.setPregnancyMode(true);
      await settingsRepository.setPregnancyLmp(event.lmp);
      emit(state.copyWith(
        pregnancyModeEnabled: true,
        pregnancyLmp: event.lmp,
        message: 'Pregnancy mode enabled',
        error: '',
      ));
    } else {
      await settingsRepository.setPregnancyMode(false);
      // Keep LMP stored so re-enabling is one tap.
      emit(state.copyWith(
        pregnancyModeEnabled: false,
        message: 'Pregnancy mode disabled',
        error: '',
      ));
    }
  }

  FutureOr<void> _onSetLmp(
      SetPregnancyLmp event, Emitter<SettingsState> emit) async {
    await settingsRepository.setPregnancyLmp(event.lmp);
    emit(state.copyWith(
      pregnancyLmp: event.lmp,
      message: 'Due date updated',
    ));
  }
}

// Re-export for UI files that only depend on settings_bloc.dart.
typedef PregnancyContextRe = PregnancyContext;
