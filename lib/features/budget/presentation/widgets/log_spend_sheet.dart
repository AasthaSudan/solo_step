import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/expense.dart';

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Shows the LogSpendSheet as a modal bottom sheet.
///
/// [onSave] receives the chosen [SpendCategory] and the rupee amount once the
/// user confirms. It is a **dummy callback** at Layer 1 — wire to Drift /
/// `budgetProvider.logSpend(...)` in Layer 2+.
void showLogSpendSheet(
  BuildContext context, {
  required void Function(SpendCategory category, int amountInr) onSave,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    // Ensure the sheet is not dismissed accidentally mid-entry
    isDismissible: true,
    builder: (_) => _LogSpendSheet(onSave: onSave),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class _LogSpendSheet extends StatefulWidget {
  final void Function(SpendCategory category, int amountInr) onSave;

  const _LogSpendSheet({required this.onSave});

  @override
  State<_LogSpendSheet> createState() => _LogSpendSheetState();
}

class _LogSpendSheetState extends State<_LogSpendSheet> {
  SpendCategory _selected = SpendCategory.food;
  final TextEditingController _amountCtrl = TextEditingController();
  bool _hasAmount = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() {
      final filled = _amountCtrl.text.trim().isNotEmpty;
      if (filled != _hasAmount) setState(() => _hasAmount = filled);
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int? get _parsedAmount {
    final t = _amountCtrl.text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  bool get _canSave => _parsedAmount != null && _parsedAmount! > 0;

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop();
    widget.onSave(_selected, _parsedAmount!);
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 540.0 : double.infinity,
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

                // ── Sheet title ───────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(157, 78, 221, 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_card_outlined,
                        color: Color(0xFFE0AAFF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log a Spend',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20 * textScale,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Two taps — category then amount',
                          style: TextStyle(
                            color: const Color.fromRGBO(255, 255, 255, 0.4),
                            fontSize: 12 * textScale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Step 1 label ──────────────────────────────────────────
                _StepLabel(step: '1', label: 'Category', textScale: textScale),
                const SizedBox(height: 12),

                // ── Category chips (tap = step 1) ─────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SpendCategory.values.map((cat) {
                    final bool sel = cat == _selected;
                    return _CategoryChip(
                      category: cat,
                      selected: sel,
                      textScale: textScale,
                      onTap: () => setState(() => _selected = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Step 2 label ──────────────────────────────────────────
                _StepLabel(step: '2', label: 'Amount (₹)', textScale: textScale),
                const SizedBox(height: 12),

                // ── Amount field (step 2 / only real input needed) ─────────
                _AmountField(
                  controller: _amountCtrl,
                  accentColor: _selected.color,
                  textScale: textScale,
                ),
                const SizedBox(height: 8),

                // Quick-pick amounts row for even faster entry
                _QuickAmountRow(
                  amounts: const [100, 200, 500, 1000],
                  onTap: (v) {
                    _amountCtrl.text = v.toString();
                    _amountCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: _amountCtrl.text.length),
                    );
                  },
                  textScale: textScale,
                ),

                const SizedBox(height: 24),

                // ── Save button ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _canSave ? 1.0 : 0.4,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        foregroundColor: Colors.white,
                        shadowColor: const Color.fromRGBO(157, 78, 221, 0.5),
                        elevation: _canSave ? 6 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(
                        _canSave
                            ? 'Save ₹${_parsedAmount!} — ${_selected.label}'
                            : 'Enter an amount to save',
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: _canSave ? _save : null,
                    ),
                  ),
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
// Sub-widgets
// ---------------------------------------------------------------------------

class _StepLabel extends StatelessWidget {
  final String step;
  final String label;
  final double textScale;

  const _StepLabel({
    required this.step,
    required this.label,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(157, 78, 221, 0.25),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: TextStyle(
              color: const Color(0xFFE0AAFF),
              fontSize: 12 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 13 * textScale,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final SpendCategory category;
  final bool selected;
  final double textScale;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.textScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color col = category.color;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? col.withAlpha(40) : const Color.fromRGBO(255, 255, 255, 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? col : const Color.fromRGBO(255, 255, 255, 0.1),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: col.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 16,
              color: selected ? col : const Color.fromRGBO(255, 255, 255, 0.5),
            ),
            const SizedBox(width: 7),
            Text(
              category.label,
              style: TextStyle(
                color: selected ? col : const Color.fromRGBO(255, 255, 255, 0.65),
                fontSize: 14 * textScale,
                fontWeight: selected ? FontWeight.bold : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color accentColor;
  final double textScale;

  const _AmountField({
    required this.controller,
    required this.accentColor,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        // Prevent absurdly large numbers
        LengthLimitingTextInputFormatter(7),
      ],
      textInputAction: TextInputAction.done,
      style: TextStyle(
        color: Colors.white,
        fontSize: 22 * textScale,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          color: const Color.fromRGBO(255, 255, 255, 0.2),
          fontSize: 22 * textScale,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Text(
            '₹',
            style: TextStyle(
              color: accentColor,
              fontSize: 22 * textScale,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: accentColor, width: 2.0),
        ),
      ),
    );
  }
}

class _QuickAmountRow extends StatelessWidget {
  final List<int> amounts;
  final void Function(int) onTap;
  final double textScale;

  const _QuickAmountRow({
    required this.amounts,
    required this.onTap,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: amounts.map((v) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onTap(v),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.08),
                  ),
                ),
                child: Text(
                  '₹$v',
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.55),
                    fontSize: 13 * textScale,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
