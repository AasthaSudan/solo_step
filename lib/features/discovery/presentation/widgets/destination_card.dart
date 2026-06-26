import 'package:flutter/material.dart';
import '../../domain/entities/destination.dart';

/// Renders a single suggestion card in the discovery swiper deck.
class DestinationCard extends StatefulWidget {
  final Destination destination;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isCompactHeight = screenSize.height < 760;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final double cardPadding = isCompactHeight ? 18.0 : 24.0;
    final double sectionGap = isCompactHeight ? 18.0 : 28.0;
    final double itemGap = isCompactHeight ? 9.0 : 12.0;

    double scale = 1.0;
    if (_isPressed) {
      scale = 0.97;
    } else if (_isHovered) {
      scale = 1.02;
    }

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
          child: Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.05),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _isHovered
                    ? const Color.fromRGBO(199, 125, 255, 0.3)
                    : const Color.fromRGBO(255, 255, 255, 0.12),
                width: 1.5,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.25),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
                if (_isHovered)
                  const BoxShadow(
                    color: Color.fromRGBO(157, 78, 221, 0.15),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      199,
                                      125,
                                      255,
                                      0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color.fromRGBO(
                                        199,
                                        125,
                                        255,
                                        0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '₹${widget.destination.dailyBudgetEstimate.toInt()}/day',
                                    style: TextStyle(
                                      color: const Color(0xFFE0AAFF),
                                      fontSize: 12 * textScale,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_outlined,
                                  color: Color(0xFFC77DFF),
                                  size: 18,
                                ),
                              ],
                            ),
                            SizedBox(height: sectionGap),
                            Text(
                              widget.destination.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: (isTablet ? 26.0 : 22.0) * textScale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.destination.tagline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color.fromRGBO(255, 255, 255, 0.7),
                                fontSize: 15 * textScale,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: sectionGap),
                            Text(
                              'HIGHLIGHTS',
                              style: TextStyle(
                                color: const Color(0xFFC77DFF),
                                fontSize: 12 * textScale,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...widget.destination.highlights
                                .take(4)
                                .map(
                                  (highlight) => Padding(
                                    padding: EdgeInsets.only(bottom: itemGap),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 6.0),
                                          child: Icon(
                                            Icons.circle,
                                            size: 6,
                                            color: Color(0xFFC77DFF),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            highlight,
                                            style: TextStyle(
                                              color: const Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                0.8,
                                              ),
                                              fontSize: 14 * textScale,
                                              fontWeight: FontWeight.w500,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                        SizedBox(height: sectionGap),
                        Container(
                          padding: EdgeInsets.all(
                            isCompactHeight ? 12.0 : 14.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(234, 67, 53, 0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromRGBO(234, 67, 53, 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFFEA4335),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.destination.safetyNote,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: const Color.fromRGBO(
                                      255,
                                      255,
                                      255,
                                      0.75,
                                    ),
                                    fontSize: 13 * textScale,
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
