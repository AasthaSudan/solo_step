/// Domain entity representing the financial summary of an active trip.
class BudgetSummary {
  final int totalBudgetInr;
  final int dailyTargetInr; // totalBudget / durationDays
  final int spentInr; // sum of logged expenses
  final int estimatedToDateInr; // sum of estCostInr for elapsed days

  const BudgetSummary({
    required this.totalBudgetInr,
    required this.dailyTargetInr,
    required this.spentInr,
    required this.estimatedToDateInr,
  });

  /// Positive => over budget vs the plan so far.
  int get varianceInr => spentInr - estimatedToDateInr;

  double get variancePct =>
      estimatedToDateInr == 0 ? 0 : varianceInr / estimatedToDateInr;

  /// Whether the user is >15% over the estimated-to-date spend.
  bool get isOverThreshold => variancePct > 0.15;

  /// Fraction of the daily target already spent today (clamped 0..1 for the bar).
  double get dailyProgress => (spentInr / dailyTargetInr).clamp(0.0, 1.0);
}
