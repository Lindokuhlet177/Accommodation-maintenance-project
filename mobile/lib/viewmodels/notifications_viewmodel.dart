import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Logic and state behind Notifications and the Home bell badge.
class NotificationsViewModel extends ChangeNotifier {
  final NotificationService _service;

  NotificationsViewModel({NotificationService? service})
      : _service = service ?? NotificationService();

  // ---------- State the screens read ----------

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<AppNotification> _items = [];

  /// Unread count for the bell badge on Home.
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  /// "New" section: unread when the screen was opened.
  List<AppNotification> get newItems =>
      _items.where((n) => n.isUnread).toList();

  /// "Earlier" section: everything already seen.
  List<AppNotification> get earlierItems =>
      _items.where((n) => !n.isUnread).toList();

  bool get isEmpty => !_isLoading && _items.isEmpty;

  // ---------- Actions ----------

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _items = await _service.getNotifications();
      _unreadCount = _items.where((n) => n.isUnread).length;
    } catch (_) {
      _errorMessage = 'Could not load notifications. Pull down to try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called when the Notifications screen opens.
  /// Clears the bell badge, but keeps the "New" highlighting on screen
  /// until next time, so the student can still see what's new.
  Future<void> markAllAsRead() async {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
    try {
      await _service.markAllSeen();
    } catch (_) {
      // Not critical: the badge will just come back on the next load
    }
  }

  /// Log Out: forget the previous student's notifications.
  void clear() {
    _items = [];
    _unreadCount = 0;
    _errorMessage = null;
    notifyListeners();
  }
}