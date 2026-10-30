import 'accommodation.dart';

/// Mirrors the `room` table.
class Room {
  final int id;
  final String roomNumber;
  final int accommodationId;

  /// Filled in when we ask Supabase to include the accommodation
  /// in the same query (a "join"). Otherwise it stays null.
  final Accommodation? accommodation;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.accommodationId,
    this.accommodation,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      roomNumber: json['room_number'] as String,
      accommodationId: json['accommodation_id'] as int,
      accommodation: json['accommodation'] == null
          ? null
          : Accommodation.fromJson(json['accommodation'] as Map<String, dynamic>),
    );
  }
}