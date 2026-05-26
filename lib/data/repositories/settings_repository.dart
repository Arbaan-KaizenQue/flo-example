import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';

/// [SettingsRepository] — typed wrapper around SharedPreferences flags
/// that gate routing and Drive opt-in.
abstract class SettingsRepository {
  bool get acceptedTerms;
  bool get driveEnabled;
  bool get onboardingComplete;
  DateTime? get lastSyncedAt;

  Future<void> setAcceptedTerms(bool accepted);
  Future<void> setDriveEnabled(bool enabled);
  Future<void> setOnboardingComplete(bool done);
}

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl({required this.prefs});

  final SharedPreferences prefs;

  @override
  bool get acceptedTerms =>
      prefs.getBool(StorageKeys.acceptedTerms) ?? false;

  @override
  bool get driveEnabled =>
      prefs.getBool(StorageKeys.driveSyncEnabled) ?? false;

  @override
  bool get onboardingComplete =>
      prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  @override
  DateTime? get lastSyncedAt {
    final raw = prefs.getString(StorageKeys.lastSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> setAcceptedTerms(bool accepted) =>
      prefs.setBool(StorageKeys.acceptedTerms, accepted);

  @override
  Future<void> setDriveEnabled(bool enabled) =>
      prefs.setBool(StorageKeys.driveSyncEnabled, enabled);

  @override
  Future<void> setOnboardingComplete(bool done) =>
      prefs.setBool(StorageKeys.onboardingComplete, done);
}
