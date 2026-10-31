import 'request_status.dart';

/// One notification: a staff update to one of the student's requests.
/// Built from a status_history row plus its request's title.
class AppNotification {
  /// Status changes that come from staff (not the student's own actions).
  static const List<String> staffStatuses = ['Assigned', 'In Progress', 'Completed'];

  final int id;
  final int requestId;
  final String requestTitle;
  final RequestStatus status;
  final String kind;          // "status" or "note" (web Updates tab)
  final String? note;         // text written by the trigger or the staff member
  final DateTime createdAt;
  final bool isUnread;

  const AppNotification({
    required this.id,
    required this.requestId,
    required this.requestTitle,
    required this.status,
    required this.kind,
    this.note,
    required this.createdAt,
    required this.isUnread,
  });

  /// [seenAt] = when the student last opened Notifications (null = never).
  factory AppNotification.fromJson(Map<String, dynamic> json, DateTime? seenAt) {
    final createdAt = DateTime.parse(json['changed_at'] as String).toLocal();
    final request = json['maintenance_request'] as Map<String, dynamic>?;

    return AppNotification(
      id: json['id'] as int,
      requestId: json['request_id'] as int,
      requestTitle: request?['title'] as String? ?? 'Maintenance request',
      status: RequestStatus.fromDb(json['status'] as String),
      kind: json['kind'] as String? ?? 'status',
      note: json['note'] as String?,
      createdAt: createdAt,
      isUnread: seenAt == null || createdAt.isAfter(seenAt),
    );
  }

  bool get isNote => kind == 'note';

  /// The main sentence under the title.
  String get message {
    if (isNote) return 'Maintenance added a note to your request.';
    return switch (status) {
      RequestStatus.assigned => 'Your request has been assigned to maintenance.',
      RequestStatus.inProgress => 'Work on your request has started.',
      RequestStatus.completed => "Repair completed. Please confirm if it's fixed.",
      _ => 'Your request was updated.',
    };
  }

  /// Extra line: the staff member's own words, if any.
  /// Notes show their full text; status changes show the part after "Label: ".
  String? get detail {
    final text = note?.trim();
    if (text == null || text.isEmpty) return null;
    if (isNote) return text;

    final colon = text.indexOf(': ');
    return colon == -1 ? null : text.substring(colon + 2);
  }
}