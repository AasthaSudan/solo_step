import 'package:flutter/material.dart';

/// A small text link widget for anonymous/guest access with hover effects.
class GuestSignInLink extends StatefulWidget {
  final VoidCallback onPressed;

  const GuestSignInLink({
    super.key,
    required this.onPressed,
  });

  @override
  State<GuestSignInLink> createState() => _GuestSignInLinkState();
}

class _GuestSignInLinkState extends State<GuestSignInLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Dynamic text scaling
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            color: _isHovered ? Colors.white : Colors.white70,
            fontSize: 14 * textScaleFactor,
            fontWeight: FontWeight.w500,
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: Colors.white,
            shadows: [
              Shadow(
                color: const Color.fromRGBO(0, 0, 0, 0.2),
                offset: const Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Text(
              'Try without an account',
            ),
          ),
        ),
      ),
    );
  }
}
