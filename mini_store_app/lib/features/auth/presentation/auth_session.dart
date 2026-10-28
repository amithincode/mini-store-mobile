import 'package:flutter/foundation.dart';

/// In-memory authentication state for the current app session.
///
 class AuthSession extends ChangeNotifier {
  bool _isSignedIn = false;
  String? _email;

  bool get isSignedIn => _isSignedIn;
  String? get email => _email;

  void signIn(String email) {
    final normalized = email.trim();
    if (_isSignedIn && _email == normalized) {
      return;
    }

    _isSignedIn = true;
    _email = normalized;
    notifyListeners();
  }

  void signOut() {
    if (!_isSignedIn) {
      return;
    }

    _isSignedIn = false;
    _email = null;
    notifyListeners();
  }
}
