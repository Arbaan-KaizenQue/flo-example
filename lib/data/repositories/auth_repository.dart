import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_keys.dart';
import '../models/json_response.dart';
import '../services/auth_service.dart';

/// [AuthRepository] — contract for Google sign-in lifecycle + Drive opt-in flag.
abstract class AuthRepository {
  GoogleSignInAccount? get currentUser;
  Stream<GoogleSignInAccount?> get onUserChanged;
  bool get driveEnabled;

  Future<JsonResponse> signIn();
  Future<JsonResponse> signInSilently();
  Future<JsonResponse> signOut();
  Future<void> setDriveEnabled(bool enabled);
}

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({required this.authService, required this.prefs});

  final AuthService authService;
  final SharedPreferences prefs;

  @override
  GoogleSignInAccount? get currentUser => authService.currentUser;

  @override
  Stream<GoogleSignInAccount?> get onUserChanged => authService.onUserChanged;

  @override
  bool get driveEnabled =>
      prefs.getBool(StorageKeys.driveSyncEnabled) ?? false;

  @override
  Future<JsonResponse> signIn() => authService.signIn();

  @override
  Future<JsonResponse> signInSilently() => authService.signInSilently();

  @override
  Future<JsonResponse> signOut() async {
    await prefs.setBool(StorageKeys.driveSyncEnabled, false);
    return authService.signOut();
  }

  @override
  Future<void> setDriveEnabled(bool enabled) =>
      prefs.setBool(StorageKeys.driveSyncEnabled, enabled);
}
