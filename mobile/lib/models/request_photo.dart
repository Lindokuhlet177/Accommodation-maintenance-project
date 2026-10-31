/// Mirrors the `request_photo` table: one photo of a request.
class RequestPhoto {
  final int id;
  final int requestId;
  final String path;        // path in the request-photos bucket
  final DateTime uploadedAt;

  const RequestPhoto({
    required this.id,
    required this.requestId,
    required this.path,
    required this.uploadedAt,
  });

  factory RequestPhoto.fromJson(Map<String, dynamic> json) {
    return RequestPhoto(
      id: json['id'] as int,
      requestId: json['request_id'] as int,
      path: json['path'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String).toLocal(),
    );
  }
}