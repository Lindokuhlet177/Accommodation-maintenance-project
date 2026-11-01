import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

/// Reads the student's notifications and records when they were seen.
class NotificationService {
  final SupabaseClient _client;

  NotificationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Newest 50 staff updates and notes on the student's OWN requests.
  Future<List<AppNotification>> getNotifications() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    // 1. When did the student last open Notifications?
    final student = await _client
        .from('student')
        .select('notifications_seen_at')
        .eq('id', userId)
        .maybeSingle();

    final seenRaw = student?['notifications_seen_at'] as String?;
    final seenAt = seenRaw == null ? null : DateTime.parse(seenRaw).toLocal();

    // 2. Staff status changes OR staff notes, on THIS student's requests only.
    //    maintenance_request!inner + the student_id filter keeps only their own,
    //    even if an account also has staff rights. RLS still applies underneath.
    final rows = await _client
        .from('status_history')
        .select('id, request_id, status, kind, note, changed_at, '
            'maintenance_request!inner(title, student_id)')
        .eq('maintenance_request.student_id', userId)
        .or('kind.eq.note,status.in.(Assigned,"In Progress",Completed)')
        .order('changed_at', ascending: false)
        .limit(50);

    return rows.map((r) => AppNotification.fromJson(r, seenAt)).toList();
  }

  /// Opening the Notifications screen: everything up to now is "seen".
  Future<void> markAllSeen() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('student')
        .update({'notifications_seen_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', userId);
  }
}
