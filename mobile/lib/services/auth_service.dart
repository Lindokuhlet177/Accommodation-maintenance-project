import 'package:supabase_flutter/supabase_flutter.dart';

/// Everything to do with logging in, signing up and logging out.
/// Only services talk to Supabase; ViewModels call these methods.
class AuthService {
  final SupabaseClient _client;

  /// Uses the app's Supabase connection by default.
  /// (Passing a client in makes the class easy to test later.)
  AuthService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// The logged-in user, or null if nobody is logged in.
  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  /// Fires whenever someone logs in or out.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Login screen.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign up screen.
  /// Returns true if the student must confirm their email before logging in.
   /// Sign up screen.
  /// Returns true if the student must confirm their email before logging in.
  Future<bool> signUp({
    required String name,
    required String surname,
    required String studentNumber,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      // Read by the handle_new_student trigger: student number + surname
      // are matched against the landlord's tenant list
      data: {
        'account_type': 'student',
        'name': name.trim(),
        'surname': surname.trim(),
        'student_number': studentNumber.trim().toUpperCase(),
      },
    );

    // No session yet means Supabase sent a confirmation email
    return response.session == null;
  }

  /// Profile > Log Out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}