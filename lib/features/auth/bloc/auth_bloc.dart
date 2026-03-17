import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth bloc wired to Supabase (email/password). When Supabase is not
/// configured, falls back to unauthenticated and no-op for login/register.
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);

    if (SupabaseConfig.isConfigured) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((_) => add(const CheckAuthStatusEvent()));
      add(const CheckAuthStatusEvent());
    } else {
      add(const CheckAuthStatusEvent());
    }
  }

  StreamSubscription<AuthState>? _authSubscription;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AppAuthState> emit) async {
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(const AuthLoading());
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      emit(const AuthAuthenticated());
    } on AuthException catch (e) {
      emit(AuthError(_loginErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
      RegisterEvent event, Emitter<AppAuthState> emit) async {
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(const AuthLoading());
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: event.email,
        password: event.password,
        data: event.fullName != null && event.fullName!.isNotEmpty
            ? {'full_name': event.fullName}
            : null,
      );
      if (response.session != null) {
        emit(const AuthAuthenticated());
      } else {
        emit(AuthEmailConfirmationRequired(event.email));
      }
    } on AuthException catch (e) {
      emit(AuthError(_registerErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  static String _registerErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('error sending') ||
        msg.contains('unexpected_failure') ||
        msg.contains('confirmation mail')) {
      return 'We couldn\'t send the confirmation email. Check Supabase Auth → SMTP (Resend: API key, sender onboarding@resend.dev, port 465).';
    }
    return e.message;
  }

  /// User-friendly message for login errors (e.g. email not confirmed).
  static String _loginErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('email not confirmed') ||
        msg.contains('confirm your email') ||
        msg.contains('not confirmed')) {
      return 'Please verify your email first. Check your inbox for the confirmation link, then try again.';
    }
    return e.message;
  }

  Future<void> _onGoogleLogin(
      GoogleLoginEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogout(
      LogoutEvent event, Emitter<AppAuthState> emit) async {
    if (SupabaseConfig.isConfigured) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onResetPassword(
      ResetPasswordEvent event, Emitter<AppAuthState> emit) async {
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthError('Backend not configured'));
      return;
    }
    emit(const AuthLoading());
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(event.email);
      emit(const PasswordResetSent());
    } on AuthException catch (e) {
      emit(AuthError(_resetPasswordErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  /// User-friendly message for reset-password errors (e.g. rate limit, SMTP).
  static String _resetPasswordErrorMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.statusCode;
    final isRateLimit = code == 429 ||
        code == '429' ||
        msg.contains('rate limit') ||
        msg.contains('too many');
    if (isRateLimit) {
      return 'Too many emails sent. Please wait an hour and try again, or use a different email.';
    }
    if (msg.contains('error sending recovery email') ||
        msg.contains('unexpected_failure') ||
        (e.statusCode?.toString() == '500' && msg.contains('recovery'))) {
      return 'We couldn\'t send the reset email. Check that Resend SMTP is set up in Supabase (Settings → Auth → SMTP): correct API key, sender onboarding@resend.dev, port 465.';
    }
    return e.message;
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event, Emitter<AppAuthState> emit) async {
    if (!SupabaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }
}
