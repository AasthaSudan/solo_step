import 'package:flutter/material.dart';
import '../../domain/entities/itinerary_day.dart';
import 'activity_line_item.dart';

/// An expandable card representing a single day's itinerary.
class DayCard extends StatefulWidget {
  final ItineraryDay day;
  final bool initiallyExpanded;

  const DayCard({
    super.key,
    required this.day,
    this.initiallyExpanded = false,
  });

  @override
  State<DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<DayCard> with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      upperBound: 0.5, // Rotate 180 degrees (0.5 turns)
    );
    if (_isExpanded) {
      _iconController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _iconController.forward();
      } else {
        _iconController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isExpanded ? const Color.fromRGBO(199, 125, 255, 0.25) : const Color.fromRGBO(255, 255, 255, 0.1),
          width: _isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Tappable Header
            InkWell(
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day ${widget.day.dayNumber}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.day.stayCost > 0 
                                ? 'Stay: ${widget.day.stayName}  •  ₹${widget.day.stayCost.toInt()}'
                                : 'No overnight stay',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color.fromRGBO(255, 255, 255, 0.5),
                              fontSize: 13 * textScale,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Rotating arrow icon
                    RotationTransition(
                      turns: _iconController,
                      child: const Icon(
                        Icons.keyboard_arrow_down_outlined,
                        color: Color(0xFFC77DFF),
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Animated expansion section
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.fastOutSlowIn,
              child: _isExpanded
                  ? Container(
                      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),
                          const SizedBox(height: 10),

                          // Activities Line Items
                          ...widget.day.activities.map((activity) {
                            return ActivityLineItem(activity: activity);
                          }),

                          const SizedBox(height: 16),
                          const Divider(color: Color.fromRGBO(255, 255, 255, 0.08), height: 1),
                          const SizedBox(height: 16),

                          // Dining & Food Suggestions Box
                          Text(
                            'DIETARY RECOMMENDATIONS',
                            style: TextStyle(
                              color: const Color(0xFFC77DFF),
                              fontSize: 11 * textScale,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14.0),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(199, 125, 255, 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromRGBO(199, 125, 255, 0.15),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.day.foodSuggestions.map((food) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 4.0),
                                        child: Icon(
                                          Icons.fastfood_outlined,
                                          size: 14,
                                          color: Color(0xFFE0AAFF),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          food,
                                          style: TextStyle(
                                            color: const Color.fromRGBO(255, 255, 255, 0.75),
                                            fontSize: 13 * textScale,
                                            fontWeight: FontWeight.w400,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
