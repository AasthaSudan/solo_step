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
    const Color selectedBg = Color(0xFF2C3E50); 
    const Color selectedBorder = Color(0xFF2C3E50); 
    const Color unselectedBg = Colors.white;
    final Color unselectedBorder = Colors.grey.shade200;

    final Color activeBg = widget.isSelected ? selectedBg : unselectedBg;
    final Color activeBorder = widget.isSelected ? selectedBorder : (_isHovered ? Colors.grey.shade400 : unselectedBorder);
    final Color activeText = widget.isSelected ? Colors.white : const Color(0xFF1A1A1A);

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
                    color: Colors.black.withOpacity(0.1),
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
