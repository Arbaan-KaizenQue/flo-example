// App-level non-API constants.

class AppConstants {
  AppConstants._();

  static const String backupFileName = 'backup.json';
  static const int backupSnapshotVersion = 1;

  static const Duration syncDebounce = Duration(seconds: 5);
  static const Duration lifecycleSyncThreshold = Duration(minutes: 5);

  static const String driveAppDataScope =
      'https://www.googleapis.com/auth/drive.appdata';
}
