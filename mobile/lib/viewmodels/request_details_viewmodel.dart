import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_request.dart';
import '../models/request_status.dart';
import '../models/status_history.dart';
import '../services/request_service.dart';
import '../services/storage_service.dart';

/// Logic and state behind Request Details and Completed.
class RequestDetailsViewModel extends ChangeNotifier {
  final RequestService _requestService;
  final StorageService _storageService;

  RequestDetailsViewModel({
    RequestService? requestService,
    StorageService? storageService,
  })  : _requestService = requestService ?? RequestService(),
        _storageService = storageService ?? StorageService();

  // ---------- State the screen reads ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MaintenanceRequest? _request;
  MaintenanceRequest? get request => _request;

  /// Temporary signed links for the photos, in upload order.
  List<String> _photoUrls = [];
  List<String> get photoUrls => _photoUrls;

  // ---------- Values ready for the screen ----------

  String get accommodationName => _request?.room?.accommodation?.name ?? '-';

  String get roomNumber => _request?.room?.roomNumber ?? '-';

  /// Timeline entries, oldest first (sorted in the model).
  List<StatusHistory> get timeline => _request?.history ?? [];

  /// Show "Confirm Resolution" only when staff marked it Completed.
  bool get canConfirmResolution => _request?.status.awaitingConfirmation ?? false;

  /// Show the Completed layout once the student confirmed it's fixed.
  bool get isClosed => _request?.status == RequestStatus.closed;

  /// Delete is allowed only while staff haven't touched it:
  /// still Open and the timeline only has "Request submitted".
  bool get canDelete =>
      _request != null &&
      _request!.status == RequestStatus.open &&
      _request!.history.length <= 1;

  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  // ---------- Actions the screen calls ----------

  Future<void> load(int requestId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _request = await _requestService.getRequestById(requestId);
      _photoUrls = await _loadPhotoUrls(_request!);
    } catch (_) {
      _errorMessage = 'Could not load this request. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// After Confirm Resolution, reload to show the new status and timeline.
  Future<void> refresh() async {
    if (_request != null) await load(_request!.id);
  }

  /// "Delete request": returns true if the request was deleted.
  Future<bool> deleteRequest() async {
    final request = _request;
    if (request == null || _isDeleting) return false;

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoPaths = await _requestService.deleteRequest(request.id);
      await _storageService.removePhotos(photoPaths);
      return true;
    } on PostgrestException catch (e) {
      // e.g. "Maintenance has already updated this request…"
      _errorMessage = e.message;
      await refresh(); // show the latest status
      return false;
    } catch (_) {
      _errorMessage = 'Could not delete the request. Check your connection.';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  // ---------- Private helpers ----------

  /// Missing or broken photos should not stop the details from showing.
  Future<List<String>> _loadPhotoUrls(MaintenanceRequest request) async {
    if (request.photos.isEmpty) return [];
    try {
      return await _storageService
          .getPhotoUrls(request.photos.map((p) => p.path).toList());
    } catch (_) {
      return []; // screen shows a "no photo" placeholder instead
    }
  }
}