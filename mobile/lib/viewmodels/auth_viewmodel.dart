import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

/// Result of a sign-up attempt, so the screen knows where to go next.
enum SignUpResult { loggedIn, needsEmailConfirmation }

/// Logic and state behind the Login and Sign up screens.
class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;

  AuthViewModel({AuthService? authService})
      : _authService = authService ?? AuthService();

  // ---------- State the screens read ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _authService.isLoggedIn;

  // ---------- Actions the screens call ----------

  /// Returns true if login worked.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } on AuthException catch (e) {
      _errorMessage = _friendlyMessage(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Check your internet connection.';
      return false;
    } finally {
      _stopLoading();
    }
  }

  /// Returns what happened, or null if sign-up failed.
   Future<SignUpResult?> signUp({
    required String name,
    required String surname,
    required String studentNumber,
    required String email,
    required String password,
  }) async {
    _startLoading();
    try {
      final needsConfirmation = await _authService.signUp(
        name: name,
        surname: surname,
        studentNumber: studentNumber,
        email: email,
        password: password,
      );
      return needsConfirmation
          ? SignUpResult.needsEmailConfirmation
          : SignUpResult.loggedIn;
    } on AuthException catch (e) {
      _errorMessage = _friendlyMessage(e);
      return null;
    } catch (_) {
      _errorMessage = 'Something went wrong. Check your internet connection.';
      return null;
    } finally {
      _stopLoading();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    notifyListeners();
  }

  /// Called when the student starts typing again.
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ---------- Private helpers ----------

  void _startLoading() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _stopLoading() {
    _isLoading = false;
    notifyListeners();
  }

  /// Turns Supabase error codes into messages a student understands.
  String _friendlyMessage(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please confirm your email first. Check your inbox.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists.';
      case 'weak_password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Too many attempts. Please wait a minute and try again.';
           default:
        // The database refuses a student number that's already registered
        if (e.message.contains('Database error saving new user')) {
          return 'This student number is already registered. '
              'If it is yours, please contact your landlord.';
        }
        return e.message;
    }
  }
}