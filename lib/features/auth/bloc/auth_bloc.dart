import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Simple in-memory auth bloc used only for UI flow.
/// No API or backend calls are performed here.
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);

    // Check auth status on initialization
    add(const CheckAuthStatusEvent());
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthLoading());
    // Simulate a short delay for UX; no real API call.
    await Future.delayed(const Duration(milliseconds: 800));
    emit(const AuthAuthenticated());
  }

  Future<void> _onRegister(
      RegisterEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    emit(const AuthAuthenticated());
  }

  Future<void> _onGoogleLogin(
      GoogleLoginEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 600));
    emit(const AuthAuthenticated());
  }

  Future<void> _onLogout(
      LogoutEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onResetPassword(
      ResetPasswordEvent event, Emitter<AppAuthState> emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    emit(const PasswordResetSent());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event, Emitter<AppAuthState> emit) async {
    // Always start unauthenticated for now.
    emit(const AuthUnauthenticated());
  }
}

