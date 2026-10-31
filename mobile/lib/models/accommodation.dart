/// Mirrors the `accommodation` table.
class Accommodation {
  final int id;
  final String name;
  final String? address; // ? = can be empty in the database

  const Accommodation({
    required this.id,
    required this.name,
    this.address,
  });

  /// Builds an Accommodation from a Supabase row.
  factory Accommodation.fromJson(Map<String, dynamic> json) {
    return Accommodation(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String?,
    );
  }
}