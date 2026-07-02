import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/budget_provider.dart';
import '../../domain/entities/expense.dart';
import 'package:solo_step/features/budget/presentation/widgets/log_spend_sheet.dart';

class BudgetDashboardView extends ConsumerWidget {
  final String tripId;

  const BudgetDashboardView({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider(tripId));
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return budgetAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFC77DFF))),
      error: (err, stack) => Center(
        child: Text('Error loading budget: $err', style: const TextStyle(color: Colors.redAccent)),
      ),
      data: (state) {
        final summary = state.summary;
        final expenses = state.expenses;
        
        final hasBudget = summary.totalBudgetInr > 0;
        final spent = summary.spentInr;
        final budget = summary.totalBudgetInr;
        
        final progress = hasBudget ? (spent / budget).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: hasBudget 
            ? _buildDashboard(context, ref, summary, expenses, progress, formatter, textScale)
            : _buildEmptyState(context, ref, textScale),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref, double textScale) {
    final controller = TextEditingController();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined, size: 80, color: Color(0xFFE0AAFF)),
            const SizedBox(height: 24),
            Text(
              'Set Your Trip Budget',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'To start tracking expenses, set a target budget for this trip.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 0.7),
                fontSize: 16 * textScale,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
                labelText: 'Total Budget (INR)',
                labelStyle: const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.6)),
                filled: true,
                fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF9D4EDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.1)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  final amount = int.tryParse(controller.text) ?? 0;
                  if (amount > 0) {
                    ref.read(budgetProvider(tripId).notifier).setBudget(amount);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Start Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, dynamic summary, List<Expense> expenses, double progress, NumberFormat formatter, double textScale) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        // Circular Progress
        Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: CategoryDonutPainter(
                    expenses: expenses,
                    totalBudget: summary.totalBudgetInr,
                    strokeWidth: 12,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Spent',
                        style: TextStyle(
                          color: const Color.fromRGBO(255, 255, 255, 0.6),
                          fontSize: 14 * textScale,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatter.format(summary.spentInr),
                        style: TextStyle(
                          color: progress > 1.0 ? Colors.redAccent : Colors.white,
                          fontSize: 28 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${formatter.format(summary.totalBudgetInr)}',
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
          ),
        ),
        const SizedBox(height: 32),
        
        Text(
          'Recent Transactions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * textScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        if (expenses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Center(
              child: Text(
                'No expenses logged yet.',
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 0.4),
                  fontSize: 16 * textScale,
                ),
              ),
            ),
          )
        else
          ..._buildGroupedExpenses(expenses, formatter, textScale),
          
        const SizedBox(height: 80), // Padding for FAB
      ],
    );
  }

  Widget _buildExpenseTile(Expense expense, NumberFormat formatter, double textScale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: expense.category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(expense.category.icon, color: expense.category.color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.category.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, h:mm a').format(expense.spentAt),
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.6),
                    fontSize: 12 * textScale,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '-${formatter.format(expense.amountInr)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedExpenses(List<Expense> expenses, NumberFormat formatter, double textScale) {
    Map<int, List<Expense>> groupedByDay = {};
    for (final e in expenses) {
      groupedByDay.putIfAbsent(e.day, () => []).add(e);
    }
    final sortedDays = groupedByDay.keys.toList()..sort((a, b) => b.compareTo(a));

    List<Widget> widgets = [];
    for (final day in sortedDays) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            day == 0 ? 'Pre-trip' : 'Day $day',
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.6),
              fontSize: 14 * textScale,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      widgets.addAll(
        groupedByDay[day]!.map((e) => _buildExpenseTile(e, formatter, textScale)),
      );
    }
    return widgets;
  }
}

class CategoryDonutPainter extends CustomPainter {
  final List<Expense> expenses;
  final int totalBudget;
  final double strokeWidth;

  CategoryDonutPainter({
    required this.expenses,
    required this.totalBudget,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = const Color.fromRGBO(255, 255, 255, 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (totalBudget <= 0) return;

    Map<SpendCategory, int> categoryTotals = {};
    int totalSpent = 0;
    for (var e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + e.amountInr;
      totalSpent += e.amountInr;
    }

    if (totalSpent > totalBudget) {
      final overPaint = Paint()
        ..color = Colors.redAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, -pi / 2, 2 * pi, false, overPaint);
      return;
    }

    double startAngle = -pi / 2;
    for (var cat in SpendCategory.values) {
      final amount = categoryTotals[cat] ?? 0;
      if (amount == 0) continue;

      final sweepAngle = (amount / totalBudget) * 2 * pi;
      final paint = Paint()
        ..color = cat.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) => true;
}

