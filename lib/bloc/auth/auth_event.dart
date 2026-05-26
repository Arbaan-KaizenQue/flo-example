part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class TryRestoreSession extends AuthEvent {
  const TryRestoreSession();
}

class SignInRequested extends AuthEvent {
  const SignInRequested();
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class UserChanged extends AuthEvent {
  const UserChanged({required this.user});

  final GoogleSignInAccount? user;

  @override
  List<Object?> get props => [user?.email];
}
