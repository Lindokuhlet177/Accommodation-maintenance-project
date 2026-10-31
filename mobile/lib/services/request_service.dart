import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_request.dart';
import '../models/request_status.dart';

/// Loads, creates, confirms and deletes maintenance requests.
class RequestService {
  final SupabaseClient _client;

  RequestService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// All of the logged-in student's requests, newest first.
  Future<List<MaintenanceRequest>> getMyRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('maintenance_request')
        .select()
        .eq('student_id', userId)
        .order('date_submitted', ascending: false);

    return data.map((row) => MaintenanceRequest.fromJson(row)).toList();
  }

  /// One request with its room, accommodation, timeline and photos.
  Future<MaintenanceRequest> getRequestById(int id) async {
    final data = await _client
        .from('maintenance_request')
        .select('*, room(*, accommodation(*)), status_history(*), request_photo(*)')
        .eq('id', id)
        .single();

    return MaintenanceRequest.fromJson(data);
  }

  /// Saves a new request and returns it (with its new id for the reference).
  Future<MaintenanceRequest> createRequest({
    required String studentId,
    required int roomId,
    required String title,
    required String category,
    required String description,
    required RequestPriority priority,
  }) async {
    final data = await _client
        .from('maintenance_request')
        .insert(MaintenanceRequest.toInsertJson(
          studentId: studentId,
          roomId: roomId,
          title: title,
          category: category,
          description: description,
          priority: priority,
        ))
        .select()
        .single();

    return MaintenanceRequest.fromJson(data);
  }

  /// Links uploaded photos to a request (one row per photo).
  Future<void> addPhotos({
    required int requestId,
    required List<String> paths,
  }) async {
    if (paths.isEmpty) return;

    await _client.from('request_photo').insert(
          paths.map((path) => {'request_id': requestId, 'path': path}).toList(),
        );
  }

  /// "Yes it's fixed" (isFixed = true) or "No, still a problem" (false).
  Future<void> confirmResolution({
    required int requestId,
    required bool isFixed,
    String? comment,
  }) async {
    final trimmed = comment?.trim();
    await _client.rpc('confirm_resolution', params: {
      'p_request_id': requestId,
      'p_is_fixed': isFixed,
      'p_comment': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    });
  }

  /// Deletes the student's own untouched request (Step D1).
  /// Returns the paths of its photos, so their files can be removed too.
  Future<List<String>> deleteRequest(int requestId) async {
    final result = await _client.rpc('delete_my_request', params: {
      'p_request_id': requestId,
    });
    return (result as List<dynamic>? ?? []).map((p) => p as String).toList();
  }
}