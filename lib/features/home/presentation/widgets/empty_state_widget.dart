import 'package:flutter/material.dart';

/// The empty-state display when the user has no active or upcoming trips.
class EmptyStateWidget extends StatefulWidget {
  final VoidCallback onPlanTripPressed;

  /// Optional callback to open the trips archive screen.
  final VoidCallback? onMyTripsPressed;

  const EmptyStateWidget({
    super.key,
    required this.onPlanTripPressed,
    this.onMyTripsPressed,
  });

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    double buttonScale = 1.0;
    if (_isPressed) {
      buttonScale = 0.96;
    } else if (_isHovered) {
      buttonScale = 1.03;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Globe Illustration Container
          Container(
            padding: EdgeInsets.all(isTablet ? 36.0 : 28.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.04),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(157, 78, 221, 0.15),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              Icons.map_outlined,
              size: isTablet ? 84.0 : 72.0,
              color: const Color(0xFFE0AAFF),
            ),
          ),
          SizedBox(height: isTablet ? 36.0 : 28.0),

          // Titles
          Text(
            'Where to next?',
            style: TextStyle(
              color: Colors.white,
              fontSize: (isTablet ? 26.0 : 22.0) * textScale,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'No active trips scheduled. Let our AI design a personalized, day-by-day travel plan based on your unique travel vibe and interests.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromRGBO(255, 255, 255, 0.6),
                fontSize: 15.0 * textScale,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 40.0 : 32.0),

          // Plan Trip CTA Button
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isPressed = true),
              onTapUp: (_) => setState(() => _isPressed = false),
              onTapCancel: () => setState(() => _isPressed = false),
              onTap: widget.onPlanTripPressed,
              child: AnimatedScale(
                scale: buttonScale,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF9D4EDD), // Violet
                        Color(0xFFC77DFF), // Light purple
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(157, 78, 221, 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      if (_isHovered)
                        BoxShadow(
                          color: const Color.fromRGBO(199, 125, 255, 0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_road,
                        size: 20 * textScale,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Plan a new trip',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Secondary link: view past trips archive
          if (widget.onMyTripsPressed != null) ...[  
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: widget.onMyTripsPressed,
              icon: const Icon(
                Icons.history_rounded,
                size: 18,
                color: Color(0xFFC77DFF),
              ),
              label: Text(
                'View past trips',
                style: TextStyle(
                  color: const Color(0xFFC77DFF),
                  fontSize: 15 * textScale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
