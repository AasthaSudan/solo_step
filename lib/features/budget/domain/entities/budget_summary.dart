class BudgetSummary {
  final int totalBudgetInr;
  final int dailyTargetInr;     // totalBudget / durationDays
  final int spentInr;           // sum of logged expenses
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
      
  bool get isOverThreshold => variancePct > 0.15; // 15% over → offer re-plan
}
