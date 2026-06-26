import 'package:flutter/material.dart';

/// A reusable selectable chip widget for onboarding multi-select grids.
/// Offers smooth scaling and color animations.
class SelectableChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<SelectableChip> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.95;
    } else if (_isHovered) {
      scale = 1.03;
    }

    // Theme colors
    final Color selectedBg = const Color(0xFF9D4EDD); // Violet
    final Color selectedBorder = const Color(0xFFC77DFF); // Light Violet
    final Color unselectedBg = const Color.fromRGBO(255, 255, 255, 0.04);
    final Color unselectedBorder = const Color.fromRGBO(255, 255, 255, 0.12);

    final Color activeBg = widget.isSelected ? selectedBg : unselectedBg;
    final Color activeBorder = widget.isSelected ? selectedBorder : (_isHovered ? const Color.fromRGBO(255, 255, 255, 0.3) : unselectedBorder);
    final Color activeText = widget.isSelected ? Colors.white : const Color(0xFFE0AAFF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: activeBg,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: activeBorder,
                width: 1.5,
              ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: const Color.fromRGBO(157, 78, 221, 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                color: activeText,
                fontSize: 14 * textScaleFactor,
                fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
