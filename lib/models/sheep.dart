class Sheep {
  final int id;
  final String tagId;
  final String gender;
  final bool? pregnant; // Now nullable
  final DateTime dob;
  final String? medicalRecords;
  final String? imageUrl;
  final double? weight;
  final String? breed;
  final String? motherId;
  final String? fatherId;

  Sheep({
    required this.id,
    required this.tagId,
    required this.gender,
    required this.pregnant,
    required this.dob,
    this.medicalRecords,
    this.imageUrl,
    this.weight,
    this.breed,
    this.motherId,
    this.fatherId,
  });

  int get age {
    final now = DateTime.now();
    int years = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  factory Sheep.fromJson(Map<String, dynamic> json) {
    final imageField = json['image'];
    final isFullUrl = imageField != null && (imageField as String).startsWith('http');
    final imageUrl = imageField != null
        ? isFullUrl
            ? imageField
            : 'https://nduwa-sheep-backend.onrender.com/uploads/$imageField'
        : null;

    return Sheep(
      id: json['id'],
      tagId: json['tag_id'],
      gender: json['gender'],
      pregnant: json['pregnant'], // Now accepts null
      dob: DateTime.parse(json['dob']),
      medicalRecords: json['medical_records'],
      imageUrl: imageUrl,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      breed: json['breed'],
      motherId: json['mother_id'],
      fatherId: json['father_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_id': tagId,
      'gender': gender,
      'pregnant': pregnant,
      'dob': dob.toIso8601String(),
      'medical_records': medicalRecords,
      'weight': weight,
      'breed': breed,
      'mother_id': motherId,
      'father_id': fatherId,
    };
  }
}
