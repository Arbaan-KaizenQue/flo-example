import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;

import '../../core/constants/app_constants.dart';
import '../models/json_response.dart';

/// [AuthService] — thin wrapper around [GoogleSignIn] scoped to the Drive
/// app-data folder. Returns [JsonResponse] like every other service.
class AuthService {
  AuthService({GoogleSignIn? googleSignIn}) : _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const [AppConstants.driveAppDataScope]);

  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  Stream<GoogleSignInAccount?> get onUserChanged => _googleSignIn.onCurrentUserChanged;

  Future<JsonResponse> signIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        return JsonResponse.failure(
          message: 'Sign-in cancelled',
          statusCode: 499,
        );
      }
      return JsonResponse.success(message: 'Signed in', data: user);
    } catch (e) {
      return JsonResponse.failure(message: 'Sign-in failed: $e');
    }
  }

  Future<JsonResponse> signInSilently() async {
    try {
      final user = await _googleSignIn.signInSilently();
      if (user == null) {
        return JsonResponse.failure(
          message: 'No silent session',
          statusCode: 401,
        );
      }
      return JsonResponse.success(message: 'Restored', data: user);
    } catch (e) {
      return JsonResponse.failure(message: 'Silent restore failed: $e');
    }
  }

  Future<JsonResponse> signOut() async {
    try {
      await _googleSignIn.signOut();
      return JsonResponse.success(message: 'Signed out');
    } catch (e) {
      return JsonResponse.failure(message: 'Sign-out failed: $e');
    }
  }

  Future<auth.AuthClient?> authenticatedClient() => _googleSignIn.authenticatedClient();
}
