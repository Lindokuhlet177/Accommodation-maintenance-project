
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';

/// Uploads request photos, creates temporary links, and removes deleted ones.
class StorageService {
  final SupabaseClient _client;

  StorageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Uploads a photo into the student's own folder. Returns its storage path.
  Future<String> uploadRequestPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be logged in to upload a photo.');
    }

    final extension = _extensionOf(fileName);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _client.storage.from(SupabaseConstants.photosBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _contentTypeFor(extension)),
        );

    return path;
  }

  /// Temporary link for one photo (expires after 1 hour).
  Future<String> getPhotoUrl(String path) async {
    return _client.storage
        .from(SupabaseConstants.photosBucket)
        .createSignedUrl(path, 60 * 60);
  }

  /// Temporary links for several photos in one call, in the same order.
  Future<List<String>> getPhotoUrls(List<String> paths) async {
    if (paths.isEmpty) return [];

    final results = await _client.storage
        .from(SupabaseConstants.photosBucket)
        .createSignedUrls(paths, 60 * 60);

    final byPath = {for (final r in results) r.path: r.signedUrl};
    return paths.map((p) => byPath[p]).whereType<String>().toList();
  }

  /// Deletes photo files of a deleted request (not critical if it fails).
  Future<void> removePhotos(List<String> paths) async {
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(SupabaseConstants.photosBucket).remove(paths);
    } catch (_) {
      // The request is already gone; leftover files are harmless
    }
  }

  // ---------- helpers ----------

  String _extensionOf(String fileName) {
    final parts = fileName.toLowerCase().split('.');
    final ext = parts.length > 1 ? parts.last : 'jpg';
    return ext == 'jpeg' ? 'jpg' : ext;
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
