import 'package:flutter/foundation.dart';

/// Notifier used by GoRouter to react to auth changes (login/logout).
/// Updated by [AuthBloc] listener; null means "not yet known".
class AuthStateNotifier extends ChangeNotifier {
  bool? _isAuthenticated;

  bool? get isAuthenticated => _isAuthenticated;

  set isAuthenticated(bool? value) {
    if (_isAuthenticated == value) return;
    _isAuthenticated = value;
    notifyListeners();
  }
}
