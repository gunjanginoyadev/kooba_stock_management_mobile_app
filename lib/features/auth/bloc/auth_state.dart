import 'package:equatable/equatable.dart';

abstract class AppAuthState extends Equatable {
  const AppAuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AppAuthState {
  const AuthInitial();
}

class AuthLoading extends AppAuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AppAuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AppAuthState {
  const AuthUnauthenticated();
}

/// Shown after sign-up when Supabase requires email confirmation.
class AuthEmailConfirmationRequired extends AppAuthState {
  final String email;

  const AuthEmailConfirmationRequired(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthError extends AppAuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AppAuthState {
  const PasswordResetSent();
}
