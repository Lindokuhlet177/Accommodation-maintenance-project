import 'request_photo.dart';
import 'request_status.dart';
import 'room.dart';
import 'status_history.dart';

/// Mirrors the `maintenance_request` table.
class MaintenanceRequest {
  /// Options for the Issue Category dropdown.
  static const List<String> categories = [
    'Plumbing',
    'Electrical',
    'Furniture',
    'Appliances',
    'Doors & Windows',
    'Other',
  ];

  static const int maxTitleLength = 60;
  static const int maxPhotos = 3;

  final int id;
  final String studentId;
  final int roomId;
  final String? updatedByStaffId;
  final String title;
  final String category;
  final String description;
  final RequestPriority priority;
  final RequestStatus status;
  final DateTime dateSubmitted;
  final DateTime? dateResolved;

  final Room? room;                    // when the query joins room
  final List<StatusHistory> history;   // when the query joins status_history
  final List<RequestPhoto> photos;     // when the query joins request_photo

  const MaintenanceRequest({
    required this.id,
    required this.studentId,
    required this.roomId,
    this.updatedByStaffId,
    required this.title,
    required this.category,
    required this.description,
    required this.priority,
    required this.status,
    required this.dateSubmitted,
    this.dateResolved,
    this.room,
    this.history = const [],
    this.photos = const [],
  });

  factory MaintenanceRequest.fromJson(Map<String, dynamic> json) {
    final historyJson = json['status_history'] as List<dynamic>? ?? [];
    final history = historyJson
        .map((h) => StatusHistory.fromJson(h as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt)); // oldest first

    final photosJson = json['request_photo'] as List<dynamic>? ?? [];
    final photos = photosJson
        .map((p) => RequestPhoto.fromJson(p as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt)); // upload order

    return MaintenanceRequest(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      roomId: json['room_id'] as int,
      updatedByStaffId: json['updated_by_staff_id'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      priority: RequestPriority.fromDb(json['priority'] as String),
      status: RequestStatus.fromDb(json['status'] as String),
      dateSubmitted: DateTime.parse(json['date_submitted'] as String).toLocal(),
      dateResolved: json['date_resolved'] == null
          ? null
          : DateTime.parse(json['date_resolved'] as String).toLocal(),
      room: json['room'] == null
          ? null
          : Room.fromJson(json['room'] as Map<String, dynamic>),
      history: history,
      photos: photos,
    );
  }

  /// Data for a new request: only the columns students may insert
  /// (Step R2 grants). Status and dates use the database defaults.
  /// Photos are saved separately, into request_photo.
  static Map<String, dynamic> toInsertJson({
    required String studentId,
    required int roomId,
    required String title,
    required String category,
    required String description,
    required RequestPriority priority,
  }) {
    return {
      'student_id': studentId,
      'room_id': roomId,
      'title': title,
      'category': category,
      'description': description,
      'priority': priority.dbValue,
    };
  }

  /// "MT 000123" for cards, details and the Submitted screen.
  String get reference => 'MT ${id.toString().padLeft(6, '0')}';
}