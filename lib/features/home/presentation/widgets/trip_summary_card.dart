import 'package:flutter/material.dart';

/// Renders a summary of an active or upcoming trip on the Home screen.
class TripSummaryCard extends StatefulWidget {
  final String destination;
  final String tagline;
  final String dates;
  final String status; // 'Active' or 'Upcoming'
  final int currentDay;
  final int totalDays;
  final VoidCallback onTap;

  const TripSummaryCard({
    super.key,
    required this.destination,
    required this.tagline,
    required this.dates,
    required this.status,
    required this.currentDay,
    required this.totalDays,
    required this.onTap,
  });

  @override
  State<TripSummaryCard> createState() => _TripSummaryCardState();
}

class _TripSummaryCardState extends State<TripSummaryCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    
    // Scale animations
    double scale = 1.0;
    if (_isPressed) {
      scale = 0.97;
    } else if (_isHovered) {
      scale = 1.02;
    }

    final double progress = widget.totalDays > 0 ? widget.currentDay / widget.totalDays : 0.0;
    final bool isActive = widget.status.toLowerCase() == 'active';
    
    // Status colors
    final Color statusColor = isActive ? const Color(0xFF34A853) : const Color(0xFFFBBC05);
    final Color statusBg = isActive ? const Color.fromRGBO(52, 168, 83, 0.15) : const Color.fromRGBO(251, 188, 5, 0.15);
    final Color statusBorderColor = isActive ? const Color.fromRGBO(52, 168, 83, 0.3) : const Color.fromRGBO(251, 188, 5, 0.3);

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
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isHovered ? const Color.fromRGBO(199, 125, 255, 0.3) : const Color.fromRGBO(255, 255, 255, 0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: const Color.fromRGBO(157, 78, 221, 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Row (Status & Dates)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusBorderColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dates
                    Text(
                      widget.dates,
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.6),
                        fontSize: 13 * textScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Destination & Tagline
                Text(
                  widget.destination,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (isTablet ? 24.0 : 20.0) * textScale,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.tagline,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.7),
                    fontSize: 15 * textScale,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Color.fromRGBO(255, 255, 255, 0.1), height: 1),
                const SizedBox(height: 20),

                // Progress Indicator Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? 'Trip Progress' : 'Time to Departure',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.5),
                        fontSize: 13 * textScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      isActive 
                          ? 'Day ${widget.currentDay} of ${widget.totalDays}'
                          : '${widget.currentDay} days left',
                      style: TextStyle(
                        color: const Color(0xFFE0AAFF),
                        fontSize: 13 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Progress Bar Track
                Stack(
                  children: [
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          height: 6,
                          width: constraints.maxWidth * (isActive ? progress : 1.0 - (widget.currentDay / 10.0).clamp(0.0, 1.0)),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9D4EDD), // Violet
                                Color(0xFFC77DFF), // Light purple
                              ],
                            ),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromRGBO(199, 125, 255, 0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
