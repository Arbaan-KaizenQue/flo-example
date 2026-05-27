import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../models/pregnancy_context.dart';

/// [SettingsRepository] — typed wrapper around SharedPreferences flags
/// that gate routing, Drive opt-in, and pregnancy mode (Feature 20).
abstract class SettingsRepository {
  bool get acceptedTerms;
  bool get driveEnabled;
  bool get onboardingComplete;
  DateTime? get lastSyncedAt;

  // Feature 20 — Pregnancy Mode
  bool get pregnancyModeEnabled;
  DateTime? get pregnancyLmp;
  PregnancyContext? get pregnancyContext;

  Future<void> setAcceptedTerms(bool accepted);
  Future<void> setDriveEnabled(bool enabled);
  Future<void> setOnboardingComplete(bool done);
  Future<void> setPregnancyMode(bool enabled);
  Future<void> setPregnancyLmp(DateTime? lmp);
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
  bool get pregnancyModeEnabled =>
      prefs.getBool(StorageKeys.pregnancyModeEnabled) ?? false;

  @override
  DateTime? get pregnancyLmp {
    final raw = prefs.getString(StorageKeys.pregnancyLmpIso);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  PregnancyContext? get pregnancyContext {
    if (!pregnancyModeEnabled) return null;
    final lmp = pregnancyLmp;
    if (lmp == null) return null;
    return PregnancyContext.fromLmp(lmp);
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

  @override
  Future<void> setPregnancyMode(bool enabled) =>
      prefs.setBool(StorageKeys.pregnancyModeEnabled, enabled);

  @override
  Future<void> setPregnancyLmp(DateTime? lmp) async {
    if (lmp == null) {
      await prefs.remove(StorageKeys.pregnancyLmpIso);
    } else {
      final dayOnly = DateTime(lmp.year, lmp.month, lmp.day);
      await prefs.setString(
        StorageKeys.pregnancyLmpIso,
        dayOnly.toIso8601String(),
      );
    }
  }
}
