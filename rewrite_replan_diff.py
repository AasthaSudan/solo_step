import re

with open('lib/features/replan/presentation/widgets/replan_diff_sheet.dart', 'r') as f:
    content = f.read()

# 1. Imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/proposed_swap.dart';
import '../providers/replan_provider.dart';
import '../../budget/presentation/providers/budget_provider.dart';"""
content = re.sub(r"import 'package:flutter/material.dart';", imports, content)

# 2. Public API
old_api = """void showReplanDiffSheet(
  BuildContext context, {
  required VoidCallback onAccept,
  required VoidCallback onDismiss,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _ReplanDiffSheet(
      onAccept: onAccept,
      onDismiss: onDismiss,
    ),
  );
}"""
new_api = """void showReplanDiffSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false, // Don't let them dismiss without acting when in loading state
    builder: (_) => const _ReplanDiffSheet(),
  );
}"""
content = content.replace(old_api, new_api)

# 3. Remove _ProposedSwap and _dummySwaps
content = re.sub(r"// ---------------------------------------------------------------------------\n// Proposed Swaps Dummy Data\n// ---------------------------------------------------------------------------\n\nclass _ProposedSwap \{[\s\S]*?const List<_ProposedSwap> _dummySwaps = \[[\s\S]*?\];", "", content)

# 4. Convert _ReplanDiffSheet to ConsumerWidget
old_class = """class _ReplanDiffSheet extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  const _ReplanDiffSheet({
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {"""
new_class = """class _ReplanDiffSheet extends ConsumerWidget {
  const _ReplanDiffSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final replanState = ref.watch(replanProvider);"""
content = content.replace(old_class, new_class)

# 5. Add loading state check
calc_totals_old = """    // Calculate totals
    const int totalOld = 5500;
    const int totalNew = 1350;
    const int totalSavings = totalOld - totalNew;"""
calc_totals_new = """    if (replanState.isLoading) {
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
                'Gemini is re-planning\\nyour itinerary...',
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

    final swaps = replanState.valueOrNull ?? [];
    
    // Calculate totals
    final int totalOld = swaps.fold(0, (sum, s) => sum + s.oldCost);
    final int totalNew = swaps.fold(0, (sum, s) => sum + s.newCost);
    final int totalSavings = totalOld - totalNew;"""
content = content.replace(calc_totals_old, calc_totals_new)

# 6. Use swaps instead of _dummySwaps
content = content.replace("_dummySwaps.map", "swaps.map")

# 7. Button callbacks
dismiss_old = """                        onPressed: () {
                          Navigator.of(context).pop();
                          onDismiss();
                        },"""
dismiss_new = """                        onPressed: () {
                          ref.read(replanProvider.notifier).dismiss();
                          Navigator.of(context).pop();
                        },"""
content = content.replace(dismiss_old, dismiss_new)

accept_old = """                        onPressed: () {
                          Navigator.of(context).pop();
                          onAccept();
                        },"""
accept_new = """                        onPressed: () {
                          ref.read(replanProvider.notifier).accept();
                          ref.read(budgetProvider.notifier).applyReplanSavings(totalSavings);
                          Navigator.of(context).pop();
                        },"""
content = content.replace(accept_old, accept_new)

# 8. _ReplanSwapCard properties
content = content.replace("class _ReplanSwapCard extends StatelessWidget {\n  final _ProposedSwap swap;", "class _ReplanSwapCard extends StatelessWidget {\n  final ProposedSwap swap;")
content = content.replace("swap.category.toUpperCase()", "swap.category.label.toUpperCase()")
content = content.replace("swap.icon", "swap.category.icon")

with open('lib/features/replan/presentation/widgets/replan_diff_sheet.dart', 'w') as f:
    f.write(content)
