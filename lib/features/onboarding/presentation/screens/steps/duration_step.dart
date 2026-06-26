import 'package:flutter/material.dart';
import '../../widgets/selectable_card.dart';

/// Step 3: Trip Duration Selection
class DurationStep extends StatelessWidget {
  final String? selectedDuration;
  final ValueChanged<String> onSelected;

  const DurationStep({
    super.key,
    required this.selectedDuration,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    final List<Map<String, dynamic>> durations = [
      {
        'key': 'weekend',
        'title': 'Weekend',
        'subtitle': '2–3 days • Quick escape or micro-adventure',
        'icon': Icons.calendar_view_week_outlined,
      },
      {
        'key': 'short_trip',
        'title': 'Short trip',
        'subtitle': '4–7 days • Perfect for exploring a single city deeply',
        'icon': Icons.date_range_outlined,
      },
      {
        'key': 'extended',
        'title': 'Extended',
        'subtitle': '1–2 weeks • Standard vacation, multiple close locations',
        'icon': Icons.calendar_month_outlined,
      },
      {
        'key': 'long_term',
        'title': 'Long-term',
        'subtitle': '2+ weeks • Slow travel, digital nomad pace, deep immersion',
        'icon': Icons.public_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your duration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * textScaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This helps Gemini optimize travel pacing, rest stops, and itinerary density.',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 15 * textScaleFactor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        ...durations.map((duration) {
          final isSelected = selectedDuration == duration['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SelectableCard(
              title: duration['title'],
              subtitle: duration['subtitle'],
              icon: duration['icon'],
              isSelected: isSelected,
              onTap: () => onSelected(duration['key']),
            ),
          );
        }),
      ],
    );
  }
}
