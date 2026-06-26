import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Hardcoded dummy defaults (Layer 1 — no BudgetSummary entity needed)
// ---------------------------------------------------------------------------
const int _kDummySpentInr = 4200;
const int _kDummyDailyTargetInr = 6000;
const int _kDummyEstimatedToDateInr = 3600; // what was planned to be spent by now
const int _kDummyTotalBudgetInr = 18000;

/// Animated budget-pacing bar widget.
///
/// Shows spent ₹ vs daily target with a gradient fill bar.
/// Colour scheme and variance chip switch to red once spend is
/// more than 15 % above [estimatedToDateInr].
///
/// **Layer 1 usage (drop-in, no data plumbing needed):**
/// ```dart
/// const PacingBar()          // uses built-in dummy numbers
/// ```
///
/// **Layer 2+ usage (pass real values from BudgetProvider):**
/// ```dart
/// PacingBar(
///   spentInr: summary.spentInr,
///   dailyTargetInr: summary.dailyTargetInr,
///   estimatedToDateInr: summary.estimatedToDateInr,
///   totalBudgetInr: summary.totalBudgetInr,
/// )
/// ```
class PacingBar extends StatelessWidget {
  /// Rupees actually logged so far today.
  final int spentInr;

  /// Daily budget target (total ÷ trip duration).
  final int dailyTargetInr;

  /// Sum of estimated costs for all activities that should have occurred
  /// by now. Used to compute variance vs actuals.
  final int estimatedToDateInr;

  /// Total trip budget (shown in the subtitle).
  final int totalBudgetInr;

  /// Called when the user taps the "Re-plan with Gemini" nudge.
  /// Pass `null` to hide the nudge banner entirely.
  final VoidCallback? onReplanTap;

  const PacingBar({
    super.key,
    this.spentInr = _kDummySpentInr,
    this.dailyTargetInr = _kDummyDailyTargetInr,
    this.estimatedToDateInr = _kDummyEstimatedToDateInr,
    this.totalBudgetInr = _kDummyTotalBudgetInr,
    this.onReplanTap,
  });

  // ── Derived values (no external entity needed) ───────────────────────────

  /// How far through the daily target the spending is (0.0 → 1.0).
  double get _progress => dailyTargetInr == 0
      ? 0.0
      : (spentInr / dailyTargetInr).clamp(0.0, 1.0);

  /// Positive = over the plan; negative = under.
  int get _varianceInr => spentInr - estimatedToDateInr;

  double get _variancePct => estimatedToDateInr == 0
      ? 0.0
      : _varianceInr / estimatedToDateInr;

  bool get _isOverThreshold => _variancePct > 0.15;

  // ── Colour tokens ─────────────────────────────────────────────────────────

  Color get _barStart =>
      _isOverThreshold ? const Color(0xFFEA4335) : const Color(0xFF9D4EDD);

  Color get _barEnd =>
      _isOverThreshold ? const Color(0xFFFF6D60) : const Color(0xFFC77DFF);

  Color get _accentLabel =>
      _isOverThreshold ? const Color(0xFFFF6D60) : const Color(0xFFE0AAFF);

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOverThreshold
              ? const Color.fromRGBO(234, 67, 53, 0.30)
              : const Color.fromRGBO(255, 255, 255, 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + title
              Row(
                children: [
                  Icon(
                    _isOverThreshold
                        ? Icons.warning_amber_rounded
                        : Icons.account_balance_wallet_outlined,
                    color: _accentLabel,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Budget Pacing',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              // Variance pill chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isOverThreshold
                      ? const Color.fromRGBO(234, 67, 53, 0.15)
                      : const Color.fromRGBO(157, 78, 221, 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOverThreshold
                      ? '+₹$_varianceInr over plan'
                      : '₹${(-_varianceInr).abs()} under plan',
                  style: TextStyle(
                    color: _accentLabel,
                    fontSize: 12 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Progress track ───────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Track background
                Container(
                  height: 10,
                  width: double.infinity,
                  color: const Color.fromRGBO(255, 255, 255, 0.06),
                ),
                // Animated gradient fill
                LayoutBuilder(
                  builder: (_, constraints) => AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 10,
                    width: constraints.maxWidth * _progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        colors: [_barStart, _barEnd],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _barStart.withAlpha(80),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Spend / target labels ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: spent amount
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '₹$spentInr ',
                      style: TextStyle(
                        color: _isOverThreshold
                            ? const Color(0xFFFF6D60)
                            : Colors.white,
                        fontSize: 15 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'spent',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.5),
                        fontSize: 13 * textScale,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: daily target
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'of ₹$dailyTargetInr',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.55),
                        fontSize: 13 * textScale,
                      ),
                    ),
                    TextSpan(
                      text: ' daily',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.3),
                        fontSize: 12 * textScale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── Trip-total sub-line ──────────────────────────────────────────
          Text(
            'Total trip budget: ₹$totalBudgetInr',
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.3),
              fontSize: 12 * textScale,
              fontWeight: FontWeight.w400,
            ),
          ),

          // ── Over-threshold Gemini nudge ──────────────────────────────────
          if (_isOverThreshold && onReplanTap != null) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: onReplanTap,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(234, 67, 53, 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color.fromRGBO(234, 67, 53, 0.22),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_fix_high_outlined,
                      color: Color(0xFFFF6D60),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You\'re 15 %+ over plan',
                            style: TextStyle(
                              color: const Color(0xFFFF6D60),
                              fontSize: 13 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap to re-plan remaining days with Gemini →',
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.65),
                              fontSize: 12 * textScale,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
