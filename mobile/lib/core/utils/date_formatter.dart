import 'package:intl/intl.dart';

/// Date formats used across the screens.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _short = DateFormat('d MMM yyyy');           // 17 Sep 2026
  static final DateFormat _withTime = DateFormat('d MMM yyyy HH:mm');  // 17 Sep 2026 10:24

  static String short(DateTime date) => _short.format(date);
  static String withTime(DateTime date) => _withTime.format(date);
    /// "Just now", "5 min ago", "3 h ago", "2 d ago", or a date after a week.
  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return short(date);
  }
}
