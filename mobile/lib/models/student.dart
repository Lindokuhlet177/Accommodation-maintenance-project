import 'room.dart';

/// Mirrors the `student` table.
class Student {
  final String id;             // uuid = same as their Supabase login id
  final String name;
  final String surname;
  final String email;
  final String? phone;
  final String? studentNumber; // filled in by the landlord
  final int? roomId;    
  final String registrationStatus; // pending / approved / declined / ended
  final int matchAttempts;         // "Try again" attempts used (max 5)       // null until the landlord assigns a room

  /// Filled in when the query includes the room (and its accommodation).
  final Room? room;

  const Student({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    this.phone,
    this.studentNumber,
    this.roomId,
    this.registrationStatus = 'pending',
    this.matchAttempts = 0,
    this.room,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      studentNumber: json['student_number'] as String?,
      roomId: json['room_id'] as int?,
      registrationStatus: json['registration_status'] as String? ?? 'pending',
      matchAttempts: json['match_attempts'] as int? ?? 0,
      room: json['room'] == null
          ? null
          : Room.fromJson(json['room'] as Map<String, dynamic>),
    );
  }

  /// Only the columns a student is allowed to change (Step 2.4 grants).
  /// Used by Edit Profile.
  Map<String, dynamic> toUpdateJson() {
    return {
      'name': name,
      'surname': surname,
      'phone': phone,
    };
  }

  // ---------- Helpers for the screens ----------

  /// "Simphiwe Sithole" for Home and Profile.
  String get fullName => '$name $surname';

  /// "SS" for the Profile avatar.
  String get initials {
    final first = name.isNotEmpty ? name[0] : '';
    final last = surname.isNotEmpty ? surname[0] : '';
    return (first + last).toUpperCase();
  }

  /// True once the landlord has linked the student to a room.
  /// Without a room, the student can't submit requests (RLS rule).
  bool get hasRoom => roomId != null;
    /// Signed up but didn't match a contract yet: can use "Try again".
  bool get needsContractMatch => !hasRoom && registrationStatus == 'pending';

  /// The landlord declined them, or their tenancy ended.
  bool get isBlocked => !hasRoom &&
      (registrationStatus == 'declined' || registrationStatus == 'ended');

  /// "Try again" attempts left (the database allows 5).
  int get attemptsLeft => (5 - matchAttempts).clamp(0, 5);
}