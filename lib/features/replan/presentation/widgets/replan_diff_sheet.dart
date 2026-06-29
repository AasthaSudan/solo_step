import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/proposed_swap.dart';
import '../providers/replan_provider.dart';
import '../../../budget/presentation/providers/budget_provider.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Shows the ReplanDiffSheet as a modal bottom sheet.
///
/// [onAccept] is triggered when the user clicks "Accept New Plan" to save changes.
/// [onDismiss] is triggered when the user rejects or dismisses the proposed re-plan.
void showReplanDiffSheet(BuildContext context, String tripId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false, // Don't let them dismiss without acting when in loading state
    builder: (_) => _ReplanDiffSheet(tripId: tripId),
  );
}



// ---------------------------------------------------------------------------
// Main Sheet Widget
// ---------------------------------------------------------------------------

class _ReplanDiffSheet extends ConsumerWidget {
  final String tripId;
  const _ReplanDiffSheet({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replanState = ref.watch(replanProvider);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    if (replanState.isLoading) {
      return Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF15102A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color.fromRGBO(199, 125, 255, 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFC77DFF)),
              const SizedBox(height: 24),
              Text(
                'Gemini is re-planning\nyour itinerary...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16 * textScale,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final swaps = replanState.value?.swaps ?? [];
    
    // Calculate totals
    final int totalOld = swaps.fold(0, (sum, s) => sum + s.oldCost);
    final int totalNew = swaps.fold(0, (sum, s) => sum + s.newCost);
    final int totalSavings = totalOld - totalNew;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 540.0 : double.infinity,
          maxHeight: screenHeight * 0.85, // Safety constraint to prevent overflow
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF15102A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(color: Color.fromRGBO(199, 125, 255, 0.2)),
                left: BorderSide(color: Color.fromRGBO(199, 125, 255, 0.1)),
                right: BorderSide(color: Color.fromRGBO(199, 125, 255, 0.1)),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ───────────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Header Title ──────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(157, 78, 221, 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFE0AAFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Budget Re-plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            'Optimized remaining itinerary to recover budget',
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.4),
                              fontSize: 12 * textScale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Cumulative Savings Banner ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(157, 78, 221, 0.15),
                        Color.fromRGBO(52, 168, 83, 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromRGBO(199, 125, 255, 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.savings_rounded,
                        color: Color(0xFF34A853),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target Saved: ₹$totalSavings',
                              style: TextStyle(
                                color: const Color(0xFF34A853),
                                fontSize: 15 * textScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Itinerary cost reduced from ₹$totalOld to ₹$totalNew',
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 0.6),
                                fontSize: 11 * textScale,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Proposed Changes Title ────────────────────────────────
                Text(
                  'PROPOSED CHANGES',
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.4),
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Scrollable List of Swaps ──────────────────────────────
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: swaps.map((swap) {
                        return _ReplanSwapCard(
                          swap: swap,
                          textScale: textScale,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Bottom Action Buttons ─────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                          side: const BorderSide(
                            color: Color.fromRGBO(255, 255, 255, 0.15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          ref.read(replanProvider.notifier).dismiss();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Dismiss',
                          style: TextStyle(
                            fontSize: 15 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shadowColor: const Color.fromRGBO(52, 168, 83, 0.4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          ref.read(replanProvider.notifier).accept();
                          ref.read(budgetProvider(tripId).notifier).applyReplanSavings(totalSavings);
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Accept Plan',
                          style: TextStyle(
                            fontSize: 15 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card displaying a single activity swap comparison
// ---------------------------------------------------------------------------

class _ReplanSwapCard extends StatelessWidget {
  final ProposedSwap swap;
  final double textScale;

  const _ReplanSwapCard({
    required this.swap,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    final int savings = swap.oldCost - swap.newCost;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(255, 255, 255, 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Swap header / category + savings
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      swap.category.icon,
                      size: 14,
                      color: const Color(0xFFC77DFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      swap.category.label.toUpperCase(),
                      style: TextStyle(
                        color: const Color(0xFFE0AAFF),
                        fontSize: 11 * textScale,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(52, 168, 83, 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color.fromRGBO(52, 168, 83, 0.35),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'Save ₹$savings',
                    style: TextStyle(
                      color: const Color(0xFF34A853),
                      fontSize: 11 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color.fromRGBO(255, 255, 255, 0.06), height: 1),

          // Old Item Details (Original)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(234, 67, 53, 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_rounded,
                    size: 10,
                    color: Color(0xFFFF6D60),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    swap.oldTitle,
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.4),
                      fontSize: 13 * textScale,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: const Color.fromRGBO(255, 255, 255, 0.3),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${swap.oldCost}',
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.35),
                    fontSize: 13 * textScale,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),

          // Flow link indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 13,
                  color: Color.fromRGBO(255, 255, 255, 0.25),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    color: const Color.fromRGBO(255, 255, 255, 0.03),
                  ),
                ),
              ],
            ),
          ),

          // New Item Details (Optimized alternative)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(52, 168, 83, 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 10,
                    color: Color(0xFF34A853),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    swap.newTitle,
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.9),
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${swap.newCost}',
                  style: TextStyle(
                    color: const Color(0xFF34A853),
                    fontSize: 14 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
