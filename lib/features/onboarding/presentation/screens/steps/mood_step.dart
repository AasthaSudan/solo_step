import 'package:flutter/material.dart';
import '../../widgets/selectable_card.dart';

/// Step 1: Mood/Vibe Selection
class MoodStep extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onSelected;

  const MoodStep({
    super.key,
    required this.selectedMood,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    final List<Map<String, dynamic>> moods = [
      {
        'key': 'chill',
        'title': 'Chill',
        'subtitle': 'Relaxing beaches, slow walks, and quiet cafes',
        'icon': Icons.beach_access_outlined,
      },
      {
        'key': 'adventure',
        'title': 'Adventure',
        'subtitle': 'Trekking, exploring wild nature, and adrenaline rushes',
        'icon': Icons.terrain_outlined,
      },
      {
        'key': 'spiritual',
        'title': 'Spiritual',
        'subtitle': 'Temples, yoga sessions, and mindful self-discovery',
        'icon': Icons.self_improvement_outlined,
      },
      {
        'key': 'culture',
        'title': 'Culture',
        'subtitle': 'Museums, ancient history, local arts, and architecture',
        'icon': Icons.museum_outlined,
      },
      {
        'key': 'party',
        'title': 'Party',
        'subtitle': 'Lively nightlife, pub crawls, music festivals, and new friends',
        'icon': Icons.nightlife_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your vibe',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * textScaleFactor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This personalizes the initial tone and recommendation style of the trip.',
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 15 * textScaleFactor,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),
        ...moods.map((mood) {
          final isSelected = selectedMood == mood['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SelectableCard(
              title: mood['title'],
              subtitle: mood['subtitle'],
              icon: mood['icon'],
              isSelected: isSelected,
              onTap: () => onSelected(mood['key']),
            ),
          );
        }),
      ],
    );
  }
}
