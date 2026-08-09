import 'package:flutter/material.dart';

/// A reusable selectable card widget for onboarding quiz options.
/// Features smooth scale, elevation, border glow transitions, and hover support.
class SelectableCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    
    // Animate scale on hover or press
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.97;
    } else if (_isHovered) {
      scale = 1.02;
    }

    // Colors matching a premium light theme
    const Color selectedBorderColor = Color(0xFF2C3E50);
    final Color selectedBgColor = const Color(0xFF2C3E50).withOpacity(0.04);
    final Color unselectedBorderColor = Colors.grey.shade200;
    const Color unselectedBgColor = Colors.white;
    
    final Color activeBorderColor = widget.isSelected ? selectedBorderColor : (_isHovered ? Colors.grey.shade400 : unselectedBorderColor);
    final Color activeBgColor = widget.isSelected ? selectedBgColor : unselectedBgColor;

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
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: activeBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: activeBorderColor,
                width: widget.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (widget.isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                else if (_isHovered)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.isSelected 
                          ? const Color(0xFF2C3E50).withOpacity(0.1)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: widget.isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontSize: 17 * textScaleFactor,
                          fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: 0.15,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: widget.isSelected ? const Color(0xFF1A1A1A) : Colors.grey.shade600,
                            fontSize: 14 * textScaleFactor,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Indicator at the end
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.isSelected ? const Color(0xFF2C3E50) : Colors.grey.shade300,
                      width: widget.isSelected ? 6 : 2,
                    ),
                    color: Colors.transparent,
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
