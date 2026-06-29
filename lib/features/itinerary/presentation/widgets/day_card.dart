import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> _launchMaps(String query) async {
    if (query.isEmpty) return;
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrlStr(String? urlStr) async {
    if (urlStr == null || urlStr.isEmpty) return;
    final url = Uri.tryParse(urlStr);
    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url);
    }
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
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
                              ),
                              if (widget.day.stayCost > 0 && widget.day.stayMapsQuery != null)
                                GestureDetector(
                                  onTap: () => _launchMaps(widget.day.stayMapsQuery!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(66, 133, 244, 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.map_outlined, size: 10, color: Color(0xFF4285F4)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Maps',
                                          style: TextStyle(
                                            color: const Color(0xFF4285F4),
                                            fontSize: 9 * textScale,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (widget.day.stayCost > 0 && widget.day.stayBookingLink != null)
                                GestureDetector(
                                  onTap: () => _launchUrlStr(widget.day.stayBookingLink!),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(157, 78, 221, 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.open_in_new_outlined, size: 10, color: Color(0xFF9D4EDD)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Book',
                                          style: TextStyle(
                                            color: const Color(0xFF9D4EDD),
                                            fontSize: 9 * textScale,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
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

                          if (widget.day.stayImageUrl != null && widget.day.stayImageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.day.stayImageUrl!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

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
                                  padding: const EdgeInsets.only(bottom: 8.0),
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
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _launchMaps(food),
                                        child: const Icon(
                                          Icons.map_outlined,
                                          size: 16,
                                          color: Color(0xFF4285F4),
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

