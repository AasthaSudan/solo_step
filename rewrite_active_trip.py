with open('lib/features/active_trip/presentation/screens/active_trip_screen.dart', 'r') as f:
    content = f.read()

# 1. Imports
imports = """import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../budget/domain/entities/expense.dart';
import '../../budget/presentation/providers/budget_provider.dart';"""
content = content.replace("import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';", imports)

# 2. Remove _recentSpends list
spends_list = """/// Hardcoded dummy recent spend log entries.
const List<_SpendEntry> _recentSpends = [
  _SpendEntry(category: 'Food', label: 'Dinner at spice garden', amount: 620),
  _SpendEntry(category: 'Transport', label: 'Auto-rickshaw to hotel', amount: 180),
  _SpendEntry(category: 'Activity', label: 'Elephant sanctuary entry', amount: 350),
];"""
content = content.replace(spends_list, "")

# 3. Remove _SpendEntry class
spend_entry_class = """class _SpendEntry {
  final String category;
  final String label;
  final int amount;
  const _SpendEntry({
    required this.category,
    required this.label,
    required this.amount,
  });
}"""
content = content.replace(spend_entry_class, "")

# 4. ConsumerStatefulWidget
content = content.replace("class ActiveTripScreen extends StatefulWidget {", "class ActiveTripScreen extends ConsumerStatefulWidget {")
content = content.replace("State<ActiveTripScreen> createState() => _ActiveTripScreenState();", "ConsumerState<ActiveTripScreen> createState() => _ActiveTripScreenState();")
content = content.replace("class _ActiveTripScreenState extends State<ActiveTripScreen> {", "class _ActiveTripScreenState extends ConsumerState<ActiveTripScreen> {")

# 5. Dummy values
dummy_values = """  // ── Budget dummy values ───────────────────────────────────────────────────
  // Over-threshold demo: spend 7400 vs target 6000 (estimate to-date 6000)
  // → +23% over, which triggers the red pacing bar + re-plan nudge.
  static const int _normalSpent = 4200;
  static const int _overSpent = 7400;
  static const int _dailyTarget = 6000;
  static const int _kEstimatedToDate = 3600; // normal state
  static const int _kEstimatedToDateOver = 6000; // over-threshold demo state
  static const int _totalBudget = 18000;

  int get _spentInr => _showOverThresholdState ? _overSpent : _normalSpent;
  int get _estimatedToDate => _showOverThresholdState ? _kEstimatedToDateOver : _kEstimatedToDate;"""
content = content.replace(dummy_values, "")
content = content.replace("  // Mutable demo state for the \"over threshold\" toggle so we can demo it\n  bool _showOverThresholdState = false;\n", "")

# 6. Log Spend
old_handle_log = """  void _handleLogSpend() {
    showLogSpendSheet(
      context,
      onSave: (category, amountInr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged ₹$amountInr under ${category.label} (Mock)'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }"""
new_handle_log = """  void _handleLogSpend() {
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
  }"""
content = content.replace(old_handle_log, new_handle_log)

# 7. Demo Toggle usage in build
demo_toggle_usage = """                    // Demo toggle: normal ↔ over-threshold state
                    _DemoToggleButton(
                      isOverThreshold: _showOverThresholdState,
                      onToggle: () => setState(
                        () => _showOverThresholdState = !_showOverThresholdState,
                      ),
                    ),
                    const SizedBox(width: 8),"""
content = content.replace(demo_toggle_usage, "")

# 8. build start
build_start = """  @override
  Widget build(BuildContext context) {"""
build_end = """  @override
  Widget build(BuildContext context) {
    final budgetStateAsync = ref.watch(budgetProvider);
    final budgetState = budgetStateAsync.valueOrNull;
    final summary = budgetState?.summary;
    final expenses = budgetState?.expenses ?? [];"""
content = content.replace(build_start, build_end, 1)

# 9. PacingBar call
pacing_old = """                          child: PacingBar(
                            key: ValueKey(_showOverThresholdState),
                            spentInr: _spentInr,
                            dailyTargetInr: _dailyTarget,
                            estimatedToDateInr: _estimatedToDate,
                            totalBudgetInr: _totalBudget,
                            onReplanTap: _handleReplan,
                          ),"""
pacing_new = """                          child: summary != null 
                              ? PacingBar(
                                  spentInr: summary.spentInr,
                                  dailyTargetInr: summary.dailyTargetInr,
                                  estimatedToDateInr: summary.estimatedToDateInr,
                                  totalBudgetInr: summary.totalBudgetInr,
                                  onReplanTap: _handleReplan,
                                )
                              : const SizedBox(height: 16),"""
content = content.replace(pacing_old, pacing_new)

# 10. ReplanBanner call
banner_old = "if (_spentInr > (_estimatedToDate * 1.15).round())"
banner_new = "if (summary?.isOverThreshold == true)"
content = content.replace(banner_old, banner_new)

# 11. _RecentSpendsList call
list_old = """                        _RecentSpendsList(
                          spends: _recentSpends,
                          textScale: textScale,
                        ),"""
list_new = """                        _RecentSpendsList(
                          spends: expenses,
                          textScale: textScale,
                        ),"""
content = content.replace(list_old, list_new)

# 12. _RecentSpendsList class modification
class_old = """class _RecentSpendsList extends StatelessWidget {
  final List<_SpendEntry> spends;"""
class_new = """class _RecentSpendsList extends StatelessWidget {
  final List<Expense> spends;"""
content = content.replace(class_old, class_new)

# 13. Map removal inside _RecentSpendsList
cat_colors = """  static const Map<String, Color> _catColors = {
    'Food': Color(0xFFFBBC05),
    'Transport': Color(0xFF4285F4),
    'Activity': Color(0xFF34A853),
    'Stay': Color(0xFFC77DFF),
    'Other': Color(0xFF8AB4F8),
  };"""
content = content.replace(cat_colors, "")

color_old = "final color = _catColors[spend.category] ?? const Color(0xFF8AB4F8);"
color_new = "final color = spend.category.color;"
content = content.replace(color_old, color_new)

label_old = "spend.label,"
label_new = "spend.label,"
content = content.replace(label_old, label_new)

cat_old_usage = "spend.category,"
cat_new_usage = "spend.category.label,"
# Fix specifically where spend.category is used as text. Let's do it with split/replace manually.
# In _RecentSpendsList:
# Text(
#   spend.category,
#   style: TextStyle(
content = content.replace("Text(\n                                spend.category,\n                                style: TextStyle(", "Text(\n                                spend.category.label,\n                                style: TextStyle(")


icon_old = "_categoryIcon(spend.category)"
icon_new = "spend.category.icon"
content = content.replace(icon_old, icon_new)

# 14. Remove _categoryIcon method
import re
content = re.sub(
    r"  IconData _categoryIcon\(String category\) \{[\s\S]*?  \}\n",
    "",
    content
)

# 15. Remove _DemoToggleButton class
content = re.sub(
    r"class _DemoToggleButton extends StatelessWidget \{[\s\S]*?\}\n",
    "",
    content
)

with open('lib/features/active_trip/presentation/screens/active_trip_screen.dart', 'w') as f:
    f.write(content)
