import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../budget/domain/entities/expense.dart';
import '../../../budget/presentation/providers/budget_provider.dart';
import '../../../budget/presentation/widgets/pacing_bar.dart';
import '../../../budget/presentation/widgets/log_spend_sheet.dart';
import '../../../replan/presentation/widgets/replan_diff_sheet.dart';
import '../../../replan/presentation/providers/replan_provider.dart';
import '../../../return_signal/presentation/widgets/checkin_chip.dart';
import '../../../return_signal/presentation/widgets/return_signal_card.dart';
import '../../../return_signal/presentation/providers/check_in_provider.dart';
import '../../../debrief/domain/entities/debrief_card.dart';

// ---------------------------------------------------------------------------
// Dummy data for Layer 1
// ---------------------------------------------------------------------------

/// Hardcoded dummy "today's activities" (mocks today's itinerary day).
const List<_ActivityRow> _todayActivities = [
  _ActivityRow(
    time: '7:00 AM',
    title: 'Mattupetty Dam viewpoint walk',
    category: 'Sightseeing',
    estCost: 0,
    suggestedReturnMinutes: 75,
  ),
  _ActivityRow(
    time: '10:30 AM',
    title: 'Kerala breakfast at Sreekrishna Café',
    category: 'Food',
    estCost: 280,
    suggestedReturnMinutes: 45,
  ),
  _ActivityRow(
    time: '1:00 PM',
    title: 'Eravikulam National Park entry',
    category: 'Activity',
    estCost: 450,
    suggestedReturnMinutes: 150,
  ),
  _ActivityRow(
    time: '5:00 PM',
    title: 'Tea factory tour + tasting',
    category: 'Activity',
    estCost: 200,
    suggestedReturnMinutes: 90,
  ),
];



// ---------------------------------------------------------------------------
// Simple value-objects for dummy data (Layer 1 only)
// ---------------------------------------------------------------------------

class _ActivityRow {
  final String time;
  final String title;
  final String category;
  final int estCost;
  final int suggestedReturnMinutes;
  const _ActivityRow({
    required this.time,
    required this.title,
    required this.category,
    required this.estCost,
    required this.suggestedReturnMinutes,
  });
}



// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// The unified Active Trip dashboard.
///
/// Two parallel loops on one screen:
///  • **Financial loop** — PacingBar + "+ Log spend" → (mock) LogSpendSheet.
///    When isOverThreshold, a "Re-plan with Gemini" CTA appears.
///  • **Physical loop** — Today's activities each with a CheckinChip,
///    a "+ Check-in" button for manual ad-hoc check-ins, and a
///    ReturnSignalCard once any check-in is armed.
///
/// Layer 1: all data is hardcoded; no Riverpod, no Firebase, no Drift.
class ActiveTripScreen extends ConsumerStatefulWidget {
  /// Human-readable destination name shown in the header.
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

  void _handleManualCheckIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual Check-in Screen (Layer 2+)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleReplan() {
    final budgetStateAsync = ref.read(budgetProvider);
    final summary = budgetStateAsync.value?.summary;
    final remainingBudget = summary?.totalBudgetInr ?? 0 - (summary?.spentInr ?? 0);
    
    // Trigger the re-plan generation
    ref.read(replanProvider.notifier).requestReplan('dummyTripId', remainingBudget);

    // Show the diff sheet which will automatically show a loading spinner
    // while the provider is in a loading state.
    showReplanDiffSheet(context);
  }



  // Mock arm from the "+ Check-in" button
  void _armDemoCheckIn() {
    ref.read(checkInProvider.notifier).arm(
      tripId: 'mock_trip_1',
      activityName: 'Evening market walk',
      duration: const Duration(minutes: 120),
    );
  }

  @override
  Widget build(BuildContext context) {
    final budgetStateAsync = ref.watch(budgetProvider);
    final checkInState = ref.watch(checkInProvider);
    final budgetState = budgetStateAsync.value;
    final summary = budgetState?.summary;
    final expenses = budgetState?.expenses ?? [];
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
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

                    // Complete Trip button (navigates to DebriefScreen)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34A853), size: 24),
                      tooltip: 'Complete Trip',
                      onPressed: () {
                        final mockCard = DebriefCard(
                          personality: 'Budget Adventurer',
                          traits: const ['Street Food Scout', 'Route Planner', 'Early Riser'],
                          caption: 'Wrapped a trip with smart spending, strong check-ins, and plenty of local discoveries.',
                          savedVsEstimateInr: 2500,
                          totalSpentInr: 12500,
                          daysCount: 4,
                          topCategory: 'Food',
                          checkInsCompleted: 8,
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
                        // ════════════════════════════════════════════════════
                        // LOOP 1: Financial — Budget Pacing
                        // ════════════════════════════════════════════════════
                        _SectionHeader(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'Budget Co-Pilot',
                          textScale: textScale,
                        ),
                        const SizedBox(height: 12),

                        // Animated pacing bar — plain int API, no entity needed
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          child: summary != null 
                              ? PacingBar(
                                  spentInr: summary.spentInr,
                                  dailyTargetInr: summary.dailyTargetInr,
                                  estimatedToDateInr: summary.estimatedToDateInr,
                                  totalBudgetInr: summary.totalBudgetInr,
                                  onReplanTap: _handleReplan,
                                )
                              : const SizedBox(height: 16),
                        ),

                        const SizedBox(height: 12),

                        // Re-plan banner is now built into PacingBar's onReplanTap;
                        // keep a standalone banner only when threshold reached for extra visibility
                        if (summary?.isOverThreshold == true)
                          _ReplanBanner(onTap: _handleReplan, textScale: textScale),

                        const SizedBox(height: 12),

                        // Recent spends list
                        _RecentSpendsList(
                          spends: expenses,
                          textScale: textScale,
                        ),

                        const SizedBox(height: 12),

                        // "+ Log spend" button
                        _LogSpendButton(
                          onPressed: _handleLogSpend,
                          textScale: textScale,
                        ),

                        const SizedBox(height: 28),
                        const Divider(color: Color.fromRGBO(255, 255, 255, 0.08)),
                        const SizedBox(height: 20),

                        // ════════════════════════════════════════════════════
                        // LOOP 2: Physical — Return Signal
                        // ════════════════════════════════════════════════════
                        _SectionHeader(
                          icon: Icons.shield_outlined,
                          label: "Today's Activities & Return Signal",
                          textScale: textScale,
                        ),
                        const SizedBox(height: 12),

                        const ReturnSignalCard(),

                        // Today's activities with check-in chips
                        _TodayActivitiesList(
                          activities: _todayActivities,
                          textScale: textScale,
                        ),

                        const SizedBox(height: 16),

                        // "+ Check-in" manual button
                        _ManualCheckInButton(
                          onPressed: checkInState.checkIn == null
                              ? _armDemoCheckIn
                              : _handleManualCheckIn,
                          isArmed: checkInState.checkIn != null,
                          textScale: textScale,
                        ),

                        const SizedBox(height: 32),
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



// ---------------------------------------------------------------------------
// Sub-widgets (private, file-scoped)
// ---------------------------------------------------------------------------

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

class _ReplanBanner extends StatelessWidget {
  final VoidCallback onTap;
  final double textScale;

  const _ReplanBanner({required this.onTap, required this.textScale});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromRGBO(234, 67, 53, 0.12),
              Color.fromRGBO(157, 78, 221, 0.12),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color.fromRGBO(234, 67, 53, 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_fix_high_outlined,
                color: Color(0xFFFF6D60), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Re-plan remaining days',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Ask Gemini to suggest cheaper alternatives',
                    style: TextStyle(
                      color: const Color.fromRGBO(255, 255, 255, 0.6),
                      fontSize: 12 * textScale,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color.fromRGBO(255, 255, 255, 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

class _RecentSpendsList extends StatelessWidget {
  final List<Expense> spends;
  final double textScale;

  const _RecentSpendsList({required this.spends, required this.textScale});



  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent spends',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.5),
            fontSize: 12 * textScale,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.06)),
          ),
          child: Column(
            children: spends.asMap().entries.map((entry) {
              final i = entry.key;
              final spend = entry.value;
              final color = spend.category.color;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withAlpha(28),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            spend.category.icon,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                spend.label,
                                style: TextStyle(
                                  color:
                                      const Color.fromRGBO(255, 255, 255, 0.9),
                                  fontSize: 13 * textScale,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                spend.category.label,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11 * textScale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${spend.amountInr}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14 * textScale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < spends.length - 1)
                    const Divider(
                        color: Color.fromRGBO(255, 255, 255, 0.05), height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
class _LogSpendButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double textScale;

  const _LogSpendButton({required this.onPressed, required this.textScale});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC77DFF),
          side: const BorderSide(
              color: Color.fromRGBO(199, 125, 255, 0.4), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: Text(
          '+ Log spend',
          style: TextStyle(
            fontSize: 15 * textScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
      ),
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
        final color =
            _catColors[act.category] ?? const Color(0xFF8AB4F8);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(255, 255, 255, 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time label
                  SizedBox(
                    width: 68,
                    child: Text(
                      act.time,
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.4),
                        fontSize: 12 * textScale,
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
                            color: const Color.fromRGBO(255, 255, 255, 0.9),
                            fontSize: 14 * textScale,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            // Category chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withAlpha(28),
                                borderRadius: BorderRadius.circular(10),
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
                              const SizedBox(width: 6),
                              // Cost chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(
                                      255, 255, 255, 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.1),
                                  ),
                                ),
                                child: Text(
                                  '₹${act.estCost}',
                                  style: TextStyle(
                                    color: const Color.fromRGBO(
                                        255, 255, 255, 0.6),
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
              const SizedBox(height: 10),
              // Checkin chip aligned to end
              Align(
                alignment: Alignment.centerRight,
                child: CheckinChip(
                  activityLabel: act.title,
                  suggestedReturnMinutes: act.suggestedReturnMinutes,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ManualCheckInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isArmed;
  final double textScale;

  const _ManualCheckInButton({
    required this.onPressed,
    required this.isArmed,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFEA4335),
          side: const BorderSide(
              color: Color.fromRGBO(234, 67, 53, 0.35), width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        icon: Icon(
          isArmed ? Icons.shield : Icons.shield_outlined,
          size: 20,
        ),
        label: Text(
          isArmed ? 'Manage active check-in' : '+ Start a manual check-in',
          style: TextStyle(
            fontSize: 15 * textScale,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
