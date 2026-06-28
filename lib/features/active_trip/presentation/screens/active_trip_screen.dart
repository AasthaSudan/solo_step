import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../budget/presentation/widgets/log_spend_sheet.dart';
import '../../../replan/presentation/widgets/replan_diff_sheet.dart';
import '../../../replan/presentation/providers/replan_provider.dart';
import '../../../debrief/domain/entities/debrief_card.dart';

// ---------------------------------------------------------------------------
// Dummy data for Layer 1
// ---------------------------------------------------------------------------

const List<_ActivityRow> _todayActivities = [
  _ActivityRow(
    time: '7:00 AM',
    title: 'Mattupetty Dam viewpoint walk',
    category: 'Sightseeing',
    estCost: 0,
  ),
  _ActivityRow(
    time: '10:30 AM',
    title: 'Kerala breakfast at Sreekrishna Café',
    category: 'Food',
    estCost: 280,
  ),
  _ActivityRow(
    time: '1:00 PM',
    title: 'Eravikulam National Park entry',
    category: 'Activity',
    estCost: 450,
  ),
  _ActivityRow(
    time: '5:00 PM',
    title: 'Tea factory tour + tasting',
    category: 'Activity',
    estCost: 200,
  ),
];

class _ActivityRow {
  final String time;
  final String title;
  final String category;
  final int estCost;
  const _ActivityRow({
    required this.time,
    required this.title,
    required this.category,
    required this.estCost,
  });
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ActiveTripScreen extends ConsumerStatefulWidget {
  final String destinationName;

  const ActiveTripScreen({
    super.key,
    required this.destinationName,
  });

  @override
  ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {
  void _handleLogSpend() {
    showLogSpendSheet(
      context,
      onSave: (category, amountInr) {
        ref.read(budgetProvider.notifier).logSpend(category, amountInr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ₹$amountInr under ${category.label}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  void _handleReplan() {
    final budgetStateAsync = ref.read(budgetProvider);
    final summary = budgetStateAsync.value?.summary;
    final remainingBudget = summary?.totalBudgetInr ?? 0 - (summary?.spentInr ?? 0);
    
    ref.read(replanProvider.notifier).requestReplan('dummyTripId', remainingBudget);
    showReplanDiffSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'replan_fab',
            onPressed: _handleReplan,
            backgroundColor: const Color(0xFFC77DFF).withAlpha(40),
            icon: const Icon(Icons.auto_fix_high, color: Color(0xFFC77DFF)),
            label: const Text('Adjust Plans', style: TextStyle(color: Color(0xFFC77DFF))),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'wallet_fab',
            onPressed: _handleLogSpend,
            backgroundColor: const Color(0xFF34A853).withAlpha(40),
            icon: const Icon(Icons.account_balance_wallet, color: Color(0xFF34A853)),
            label: const Text('Log Spend', style: TextStyle(color: Color(0xFF34A853))),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C20), // Dark space blue
              Color(0xFF15102A), // Deep indigo
              Color(0xFF2E1A47), // Rich twilight purple
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                      tooltip: 'Back to Dashboard',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.destinationName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                          Text(
                            'Day 2 of 3  •  Active',
                            style: TextStyle(
                              color: const Color(0xFFC77DFF),
                              fontSize: 12 * textScale,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Complete Trip button
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34A853), size: 24),
                      tooltip: 'Complete Trip',
                      onPressed: () {
                        final mockCard = DebriefCard(
                          personality: 'Budget Adventurer',
                          traits: const ['Street Food Scout', 'Route Planner', 'Early Riser'],
                          caption: 'Wrapped a trip with smart spending and plenty of local discoveries.',
                          savedVsEstimateInr: 2500,
                          totalSpentInr: 12500,
                          daysCount: 4,
                          topCategory: 'Food',
                        );
                        context.go('/trips/debrief', extra: mockCard);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),

              // ── Main scrollable body ───────────────────────────────────────
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 540.0 : double.infinity,
                    ),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20.0),
                      children: [
                        _SectionHeader(
                          icon: Icons.map_outlined,
                          label: "Today's Itinerary",
                          textScale: textScale,
                        ),
                        const SizedBox(height: 16),
                        _TodayActivitiesList(
                          activities: _todayActivities,
                          textScale: textScale,
                        ),
                        const SizedBox(height: 80), // Padding for FABs
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final double textScale;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC77DFF), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: const Color(0xFFC77DFF),
              fontSize: 12 * textScale,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayActivitiesList extends StatelessWidget {
  final List<_ActivityRow> activities;
  final double textScale;

  const _TodayActivitiesList({
    required this.activities,
    required this.textScale,
  });

  static const Map<String, Color> _catColors = {
    'Sightseeing': Color(0xFF34A853),
    'Food': Color(0xFFFBBC05),
    'Activity': Color(0xFFC77DFF),
    'Transport': Color(0xFF4285F4),
    'Stay': Color(0xFF8AB4F8),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: activities.map((act) {
        final color = _catColors[act.category] ?? const Color(0xFF8AB4F8);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.07)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time label
              SizedBox(
                width: 72,
                child: Text(
                  act.time,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.5),
                    fontSize: 13 * textScale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act.title,
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.95),
                        fontSize: 15 * textScale,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withAlpha(28),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            act.category,
                            style: TextStyle(
                              color: color,
                              fontSize: 11 * textScale,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (act.estCost > 0) ...[
                          const SizedBox(width: 8),
                          // Cost chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color.fromRGBO(255, 255, 255, 0.1),
                              ),
                            ),
                            child: Text(
                              '₹${act.estCost}',
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 0.7),
                                fontSize: 11 * textScale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
