class Lamb {
  final int id;
  final String tagId;
  final String gender;
  final DateTime birthDate;
  final String? motherTagId;
  final String? fatherTagId;
  final String? notes;
  final String? imageUrl;
  final DateTime dateAdded;
  final double? weaningWeight; // ✅ NEW FIELD

  Lamb({
    required this.id,
    required this.tagId,
    required this.gender,
    required this.birthDate,
    this.motherTagId,
    this.fatherTagId,
    this.notes,
    this.imageUrl,
    required this.dateAdded,
    this.weaningWeight, // ✅ NEW FIELD
  });

  // ✅ Computed age in years
  int get age {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      years--;
    }
    return years;
  }

  // ✅ Computed age in days
  int get ageDays {
    final today = DateTime.now();
    return today.difference(birthDate).inDays;
  }

  // ✅ Match expected keys for UI compatibility
  String? get motherId => motherTagId;
  String? get fatherId => fatherTagId;

  factory Lamb.fromJson(Map<String, dynamic> json) {
    return Lamb(
      id: json['id'] ?? 0,
      tagId: json['tag_id'] ?? '',
      gender: json['gender'] ?? '',
      birthDate: DateTime.tryParse(json['dob'] ?? '') ?? DateTime.now(),
      motherTagId: json['mother_id'],
      fatherTagId: json['father_id'],
      notes: json['notes'],
      imageUrl: json['image_url'],
      dateAdded: DateTime.now(), // You can adjust this if backend sends it
      weaningWeight: json['weaning_weight'] != null
          ? (json['weaning_weight'] as num).toDouble()
          : null, // ✅ NEW FIELD PARSING
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_id': tagId,
      'gender': gender,
      'dob': birthDate.toIso8601String(),
      'mother_id': motherTagId,
      'father_id': fatherTagId,
      'notes': notes,
      'image_url': imageUrl,
      'date_added': dateAdded.toIso8601String(),
      'weaning_weight': weaningWeight, // ✅ NEW FIELD INCLUDED
    };
  }
}
