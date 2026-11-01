import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student.dart';

/// Reads and updates the logged-in student's own record.
class StudentService {
  final SupabaseClient _client;

  StudentService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Loads the logged-in student with their room and accommodation.
  /// Returns null if nobody is logged in or no student row exists.
  Future<Student?> getCurrentStudent() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('student')
        .select('*, room(*, accommodation(*))')
        .eq('id', userId)
        .maybeSingle();

    return data == null ? null : Student.fromJson(data);
  }

  /// Edit Profile: saves name, surname and phone only.
  Future<void> updateProfile(Student student) async {
    await _client
        .from('student')
        .update(student.toUpdateJson())
        .eq('id', student.id);
  }
    /// "Try again": saves the corrected student number and surname, then
  /// re-runs the contract matching (Step W13.1). Returns true if linked.
  Future<bool> retryContractMatch({
    required String studentNumber,
    required String surname,
  }) async {
    final result = await _client.rpc('retry_contract_match', params: {
      'p_student_number': studentNumber.trim().toUpperCase(),
      'p_surname': surname.trim(),
    });
    return result == true;
  }
}
