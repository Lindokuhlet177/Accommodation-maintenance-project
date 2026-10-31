import 'request_status.dart';

//mirrors the 'status history' table : one entry on the timeline.

class StatusHistory {
  final int id;
  final int requestId;
  final RequestStatus status;
  final String? note;
  final DateTime changedAt;
    final String kind;        // "status" or "note"

  const StatusHistory ({
    required this.id,
    required this.requestId,
    required this.status,
    this.note,
    this.kind = 'status',
    required this.changedAt

  });

  factory StatusHistory.fromJson(Map<String, dynamic> json) 
  {
    
    return StatusHistory(
      id: json['id'] as int,
      requestId: json['request_id'] as int,
      status: RequestStatus.fromDb(json['status'] as String),
      note: json['note'] as String?,
      kind: json['kind'] as String? ?? 'status',
      // Database stores UTC; show the phone's local time
      changedAt: DateTime.parse(json['changed_at'] as String).toLocal(),
    );
  }
    bool get isNote => kind == 'note';

}