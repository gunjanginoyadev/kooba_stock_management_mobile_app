import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/firebase_config.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Auth bloc wired to Firebase Auth (email/password).
class AuthBloc extends Bloc<AuthEvent, AppAuthState> {
  AuthBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<GoogleLoginEvent>(_onGoogleLogin);
    on<LogoutEvent>(_onLogout);
    on<ResetPasswordEvent>(_onResetPassword);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);

    if (FirebaseConfig.isConfigured) {
      _authSubscription = _auth.authStateChanges().listen(
            (_) => add(const CheckAuthStatusEvent()),
          );
    }
    add(const CheckAuthStatusEvent());
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSubscription;

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AppAuthState> emit) async {
    if (!FirebaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(const AuthLoading());
    try {
      await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      emit(const AuthAuthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_loginErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegister(
    RegisterEvent event,
    Emitter<AppAuthState> emit,
  ) async {
    if (!FirebaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    emit(const AuthLoading());
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      final user = credential.user;
      if (user == null) {
        emit(const AuthError('Registration failed. Please try again.'));
        return;
      }

      final fullName = event.fullName?.trim();
      if (fullName != null && fullName.isNotEmpty) {
        await user.updateDisplayName(fullName);
      }

      await _firestore.collection('profiles').doc(user.uid).set({
        'full_name': (fullName != null && fullName.isNotEmpty) ? fullName : null,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      try {
        await user.sendEmailVerification();
      } catch (_) {
        // Profile created; verification email is best-effort.
      }

      emit(const AuthAuthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_registerErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  static String _registerErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled in Firebase Auth.';
      default:
        return e.message ?? e.code;
    }
  }

  static String _loginErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return e.message ?? e.code;
    }
  }

  Future<void> _onGoogleLogin(
    GoogleLoginEvent event,
    Emitter<AppAuthState> emit,
  ) async {
    emit(const AuthUnauthenticated());
  }

  Future<void> _onLogout(
    LogoutEvent event,
    Emitter<AppAuthState> emit,
  ) async {
    if (FirebaseConfig.isConfigured) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    emit(const AuthUnauthenticated());
  }

  Future<void> _onResetPassword(
    ResetPasswordEvent event,
    Emitter<AppAuthState> emit,
  ) async {
    if (!FirebaseConfig.isConfigured) {
      emit(const AuthError('Backend not configured'));
      return;
    }
    emit(const AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: event.email.trim());
      emit(const PasswordResetSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_resetPasswordErrorMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  static String _resetPasswordErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'too-many-requests':
        return 'Too many emails sent. Please wait and try again.';
      default:
        return e.message ?? e.code;
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AppAuthState> emit,
  ) async {
    if (!FirebaseConfig.isConfigured) {
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      if (_auth.currentUser != null) {
        emit(const AuthAuthenticated());
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }
}
