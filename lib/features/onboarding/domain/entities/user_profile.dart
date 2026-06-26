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
}
