class DebriefCard {
  final String personality;
  final List<String> traits;
  final String caption;
  final int savedVsEstimateInr;
  final int totalSpentInr;
  final int daysCount;
  final String topCategory;
  final int checkInsCompleted;

  const DebriefCard({
    required this.personality,
    required this.traits,
    required this.caption,
    required this.savedVsEstimateInr,
    required this.totalSpentInr,
    required this.daysCount,
    required this.topCategory,
    required this.checkInsCompleted,
  });
}
