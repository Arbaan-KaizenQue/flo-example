import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// [AuthBloc] — Google sign-in lifecycle.
/// Style B (Initial / Loading / SignedIn / SignedOut / Failure).
///
/// Events:
/// 1) [TryRestoreSession] — attempt silent sign-in at app start.
/// 2) [SignInRequested] — interactive sign-in, flips drive flag on.
/// 3) [SignOutRequested] — sign out + flips drive flag off.
/// 4) [UserChanged] — internal, fired by the underlying user stream.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<TryRestoreSession>(_onTryRestoreSession);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<UserChanged>(_onUserChanged);

    _sub = authRepository.onUserChanged
        .listen((user) => add(UserChanged(user: user)));
  }

  final AuthRepository authRepository;
  StreamSubscription<GoogleSignInAccount?>? _sub;

  FutureOr<void> _onTryRestoreSession(
      TryRestoreSession event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await authRepository.signInSilently();
    if (res.success) {
      emit(AuthSignedIn(user: res.data as GoogleSignInAccount));
    } else {
      emit(AuthSignedOut());
    }
  }

  FutureOr<void> _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await authRepository.signIn();
    if (res.success) {
      await authRepository.setDriveEnabled(true);
      emit(AuthSignedIn(user: res.data as GoogleSignInAccount));
    } else {
      emit(AuthFailure(message: res.message));
    }
  }

  FutureOr<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepository.signOut();
    emit(AuthSignedOut());
  }

  FutureOr<void> _onUserChanged(
      UserChanged event, Emitter<AuthState> emit) {
    emit(event.user != null
        ? AuthSignedIn(user: event.user!)
        : AuthSignedOut());
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
