import 'package:flutter/material.dart';
import '../../domain/entities/debrief_card.dart';

/// A card displaying a summary of the completed trip.
///
/// Designed to be screenshot and shareable on social platforms. It combines
/// hard statistical facts from the app (rupees saved, check-ins, totals) with
/// AI-generated personality description traits.
class DebriefCardWidget extends StatelessWidget {
  final DebriefCard card;

  const DebriefCardWidget({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final bool isSaved = card.savedVsEstimateInr >= 0;
    final int absSavings = card.savedVsEstimateInr.abs();

    return AspectRatio(
      aspectRatio: 0.7, // Social poster format (approx 5:7)
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background glowing circular shapes
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C3E50).withAlpha(20),
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              left: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2C3E50).withAlpha(15),
                ),
              ),
            ),

            // Foreground Card Content layout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top branding bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C3E50).withAlpha(30),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.explore_rounded,
                              size: 14,
                                color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SOLOREADY',
                            style: TextStyle(
                              color: const Color(0xFF1A1A1A),
                              fontSize: 12 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${card.daysCount} DAYS',
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A),
                            fontSize: 10 * textScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),

                  // Travel personality title icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSaved ? Icons.emoji_events_rounded : Icons.directions_run_rounded,
                        size: 40,
                        color: isSaved ? const Color(0xFFFBBC05) : const Color(0xFF4285F4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Personality Header Text
                  Center(
                    child: Text(
                      card.personality.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF1A1A1A),
                        fontSize: 24 * textScale,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: const [
                          Shadow(
                            color: Colors.transparent,
                            blurRadius: 10,
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trait chips list
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: card.traits.map((trait) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          '#$trait',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11 * textScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Spacer(flex: 3),

                  // Hero savings block
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSaved
                            ? const Color.fromRGBO(52, 168, 83, 0.25)
                            : const Color.fromRGBO(234, 67, 53, 0.25),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isSaved ? '₹$absSavings SAVED' : '₹$absSavings OVER',
                          style: TextStyle(
                            color: isSaved ? const Color(0xFF34A853) : const Color(0xFFFF6D60),
                            fontSize: 28 * textScale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'vs. original estimated plan',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12 * textScale,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),

                  // Caption quote text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '"${card.caption}"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14 * textScale,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(flex: 4),

                  // Footer info stats row
                  Divider(color: Colors.grey.shade300, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _FooterStat(
                        label: 'Total Spent',
                        value: '₹${card.totalSpentInr}',
                        textScale: textScale,
                      ),
                      _FooterStat(
                        label: 'Top Expense',
                        value: card.topCategory,
                        textScale: textScale,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  final String label;
  final String value;
  final double textScale;

  const _FooterStat({
    required this.label,
    required this.value,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 9 * textScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontSize: 12 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
