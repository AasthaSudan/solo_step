class UserProfile {
  final String mood;
  final String budgetTier;
  final int budgetPerDayMin;
  final int budgetPerDayMax;
  final String tripDuration;
  final List<String> interests;
  final String experienceLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.mood,
    required this.budgetTier,
    required this.budgetPerDayMin,
    required this.budgetPerDayMax,
    required this.tripDuration,
    required this.interests,
    required this.experienceLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? mood,
    String? budgetTier,
    int? budgetPerDayMin,
    int? budgetPerDayMax,
    String? tripDuration,
    List<String>? interests,
    String? experienceLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      mood: mood ?? this.mood,
      budgetTier: budgetTier ?? this.budgetTier,
      budgetPerDayMin: budgetPerDayMin ?? this.budgetPerDayMin,
      budgetPerDayMax: budgetPerDayMax ?? this.budgetPerDayMax,
      tripDuration: tripDuration ?? this.tripDuration,
      interests: interests ?? this.interests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mood': mood,
      'budgetTier': budgetTier,
      'budgetPerDayMin': budgetPerDayMin,
      'budgetPerDayMax': budgetPerDayMax,
      'tripDuration': tripDuration,
      'interests': interests,
      'experienceLevel': experienceLevel,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      mood: map['mood'] as String? ?? '',
      budgetTier: map['budgetTier'] as String? ?? '',
      budgetPerDayMin: map['budgetPerDayMin'] as int? ?? 0,
      budgetPerDayMax: map['budgetPerDayMax'] as int? ?? 0,
      tripDuration: map['tripDuration'] as String? ?? '',
      interests: (map['interests'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experienceLevel: map['experienceLevel'] as String? ?? '',
      // Firestore returns Timestamp for dates, we handle both Timestamp and String just in case
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'].runtimeType.toString() == 'Timestamp' ? map['createdAt'].toDate() : DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'].runtimeType.toString() == 'Timestamp' ? map['updatedAt'].toDate() : DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
