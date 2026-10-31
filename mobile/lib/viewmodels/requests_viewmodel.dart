import 'package:flutter/foundation.dart';
import '../models/maintenance_request.dart';
import '../services/request_service.dart';

/// The filter chips at the top of My Requests.
enum RequestFilter {
  all('All'),
  open('Open'),
  inProgress('In Progress'),
  closed('Closed');

  final String label;
  const RequestFilter(this.label);
}

/// Logic and state behind the My Requests screen.
class RequestsViewModel extends ChangeNotifier {
  final RequestService _requestService;

  RequestsViewModel({RequestService? requestService})
      : _requestService = requestService ?? RequestService();

  // ---------- State the screen reads ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<MaintenanceRequest> _allRequests = [];

  RequestFilter _filter = RequestFilter.all;
  RequestFilter get filter => _filter;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// The list the screen shows, after the chip filter and search.
  List<MaintenanceRequest> get visibleRequests {
    return _allRequests.where((r) {
      // 1. Chip filter: compare with the label the student sees
      final matchesFilter =
          _filter == RequestFilter.all || r.status.chipLabel == _filter.label;

      // 2. Search: category, description or reference number
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          r.category.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query) ||
          r.reference.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();
  }

  /// Different empty messages for "no requests at all" and "no matches".
  bool get hasNoRequestsAtAll => !_isLoading && _allRequests.isEmpty;

  // ---------- Actions the screen calls ----------

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allRequests = await _requestService.getMyRequests();
    } catch (_) {
      _errorMessage = 'Could not load your requests. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  /// A filter chip was tapped.
  void setFilter(RequestFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  /// The student typed in the search box.
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Search box closed: show everything again.
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
    /// Log Out: forget the previous student's requests and filters.
  void clear() {
    _allRequests = [];
    _filter = RequestFilter.all;
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}