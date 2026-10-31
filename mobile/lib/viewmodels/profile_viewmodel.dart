import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';

/// Logic and state behind Profile and Edit Profile.
class ProfileViewModel extends ChangeNotifier {
  final StudentService _studentService;
  final AuthService _authService;

  ProfileViewModel({StudentService? studentService, AuthService? authService})
    : _studentService = studentService ?? StudentService(),
      _authService = authService ?? AuthService();

  // ---------- State the screens read ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Student? _student;
  Student? get student => _student;

  // ---------- Values ready for the screen ----------

  String get fullName => _student?.fullName ?? '';

  String get initials => _student?.initials ?? '';

  String get studentNumberLabel {
    final number = _student?.studentNumber;
    return number == null
        ? 'Student Number: not added yet'
        : 'Student Number: $number';
  }

  String get accommodationName =>
      _student?.room?.accommodation?.name ?? 'No accommodation assigned';

  String get roomLabel {
    final number = _student?.room?.roomNumber;
    return number == null ? 'Room not assigned yet' : 'Room - $number';
  }

  // ---------- Actions the screens call ----------

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _student = await _studentService.getCurrentStudent();
    } catch (_) {
      _errorMessage = 'Could not load your profile. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Edit Profile > Save. Returns true if saved.
  Future<bool> updateProfile({
    required String name,
    required String surname,
    String? phone,
  }) async {
    final current = _student;
    if (current == null) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Models are read-only, so build an updated copy
      final updated = Student(
        id: current.id,
        name: name.trim(),
        surname: surname.trim(),
        email: current.email,
        phone: (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
        studentNumber: current.studentNumber,
        roomId: current.roomId,
        room: current.room,
        registrationStatus: current.registrationStatus,
        matchAttempts: current.matchAttempts,
      );

      await _studentService.updateProfile(updated);
      _student = updated; // screen updates straight away
      return true;
    } catch (_) {
      _errorMessage = 'Could not save your changes. Please try again.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Profile > Log Out.
  Future<void> logout() async {
    await _authService.signOut();
    _student = null;
    notifyListeners();
  }
}
