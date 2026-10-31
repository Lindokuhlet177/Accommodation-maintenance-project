import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_request.dart';
import '../models/student.dart';
import '../services/request_service.dart';
import '../services/student_service.dart';

/// Logic and state behind the Home screen.
class HomeViewModel extends ChangeNotifier {
  final StudentService _studentService;
  final RequestService _requestService;

  HomeViewModel({
    StudentService? studentService,
    RequestService? requestService,
  }) : _studentService = studentService ?? StudentService(),
       _requestService = requestService ?? RequestService();

  // ---------- State the screen reads ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Student? _student;
  Student? get student => _student;

  List<MaintenanceRequest> _requests = [];

  // ---------- Values ready for the screen ----------

  /// "Simphiwe Sithole" in "Hi, Simphiwe Sithole!"
  String get fullName => _student?.fullName ?? '';

  /// "The Village Square"
  String get accommodationName =>
      _student?.room?.accommodation?.name ?? 'No accommodation assigned';

  /// "Room 201"
  String get roomLabel {
    final number = _student?.room?.roomNumber;
    return number == null ? 'Room not assigned yet' : 'Room $number';
  }

  /// Whether the student may report a problem (needs a room, RLS rule).
  bool get canReportProblem => _student?.hasRoom ?? false;

  /// Number in the "Active Requests" card.
  int get activeCount => _requests.where((r) => r.status.isActive).length;

  /// The 3 newest requests for "Recent Requests".
  List<MaintenanceRequest> get recentRequests => _requests.take(3).toList();

  // ---------- Actions the screen calls ----------

  /// Loads the student and their requests at the same time.
  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _studentService.getCurrentStudent(),
        _requestService.getMyRequests(),
      ]);
      _student = results[0] as Student?;
      _requests = results[1] as List<MaintenanceRequest>;
    } catch (_) {
      _errorMessage = 'Could not load your details. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pull-to-refresh, or after submitting a new request.
  Future<void> refresh() => load();

  /// Log Out: forget the previous student's data.
  void clear() {
    _student = null;
    _requests = [];
    _errorMessage = null;
    _retryMessage = null;
    notifyListeners();
  }

  // ---------- "Try again" (unmatched sign-up) ----------

  bool _isRetrying = false;
  bool get isRetrying => _isRetrying;

  String? _retryMessage;
  String? get retryMessage => _retryMessage;

  /// Returns true if the student is now linked to their room.
  Future<bool> retryContractMatch({
    required String studentNumber,
    required String surname,
  }) async {
    _isRetrying = true;
    _retryMessage = null;
    notifyListeners();

    try {
      final linked = await _studentService.retryContractMatch(
        studentNumber: studentNumber,
        surname: surname,
      );
      if (!linked) {
        _retryMessage =
            'Still no match. Check the details on your contract, or contact your landlord.';
      }
      await load(); // refresh: shows the room, or the new attempt count
      return linked;
    } on PostgrestException catch (e) {
      // Friendly messages from the database, e.g. "Too many attempts…"
      _retryMessage = e.message;
      return false;
    } catch (_) {
      _retryMessage = 'Could not check right now. Check your connection.';
      return false;
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }
}
