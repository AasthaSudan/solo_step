import 'package:flutter/material.dart';
import '../../widgets/selectable_card.dart';

/// Step 5: Solo Experience Level Selection
class ExperienceStep extends StatelessWidget {
  final String? selectedExperience;
  final ValueChanged<String> onSelected;

  const ExperienceStep({
    super.key,
    required this.selectedExperience,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    final List<Map<String, dynamic>> levels = [
      {
        'key': 'first_timer',
        'title': 'First-timer',
        'subtitle': 'This is my first solo trip. I would love detailed safety tips, local etiquette, and easy transport guides.',
        'icon': Icons.sentiment_satisfied_alt_outlined,
      },
      {
        'key': 'seasoned',
        'title': 'Seasoned',
        'subtitle': 'I have traveled solo before. Keep the itinerary lean, show offbeat locations, and limit basic travel warnings.',
        'icon': Icons.workspace_premium_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solo travel experience',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * textScaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We use this flag to adjust the safety warnings and level of detail in your daily itinerary.',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 15 * textScaleFactor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        ...levels.map((level) {
          final isSelected = selectedExperience == level['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: SelectableCard(
              title: level['title'],
              subtitle: level['subtitle'],
              icon: level['icon'],
              isSelected: isSelected,
              onTap: () => onSelected(level['key']),
            ),
          );
        }),
      ],
    );
  }
}
