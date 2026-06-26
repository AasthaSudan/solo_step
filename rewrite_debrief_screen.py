import re

with open('lib/features/debrief/presentation/screens/debrief_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/debrief_provider.dart';"""
content = content.replace("import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';", imports)

# Convert to ConsumerWidget
content = content.replace("class DebriefScreen extends StatelessWidget {", "class DebriefScreen extends ConsumerWidget {")
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

# Remove _dummyCard and card param
# The constructor still accepts card? No, remove the card param entirely. It relies on the provider now.
constructor_old = """  final DebriefCard? card;

  const DebriefScreen({
    super.key,
    this.card,
  });

  // Default dummy data used if no card is passed in (Layer 1 fallback)
  static const DebriefCard _dummyCard = DebriefCard(
    personality: 'Budget Adventurer',
    traits: ['Street Food Scout', 'Early Riser', 'Offbeat Trails'],
    caption: 'Found the hidden tea gardens of Munnar and saved some rupees along the way!',
    savedVsEstimateInr: 2150,
    totalSpentInr: 15350,
    daysCount: 5,
    topCategory: 'Stay',
    checkInsCompleted: 8,
  );"""
constructor_new = """  const DebriefScreen({super.key});"""
content = content.replace(constructor_old, constructor_new)

# Update build method to watch provider
build_old = """    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final currentCard = card ?? _dummyCard;
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold("""
build_new = """    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final debriefAsync = ref.watch(debriefProvider);
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Scaffold("""
content = content.replace(build_old, build_new)

# Replace the body with provider states
body_old = """                    // The Debrief Card Widget
                    DebriefCardWidget(card: currentCard),
                    const SizedBox(height: 32),

                    // Actions
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        foregroundColor: Colors.white,
                        shadowColor: const Color.fromRGBO(157, 78, 221, 0.4),
                        elevation: 8,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 20),
                      label: Text(
                        'Share Story Card',
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Mock share triggered! Card image rendering to PNG (Layer 4+)... 📸'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                        side: const BorderSide(
                          color: Color.fromRGBO(255, 255, 255, 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => context.pop(),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 16 * textScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),"""
body_new = """                    // The Debrief Card Widget
                    debriefAsync.when(
                      data: (card) {
                        if (card == null) return const SizedBox();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DebriefCardWidget(card: card),
                            const SizedBox(height: 32),

                            // Actions
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9D4EDD),
                                foregroundColor: Colors.white,
                                shadowColor: const Color.fromRGBO(157, 78, 221, 0.4),
                                elevation: 8,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.share_rounded, size: 20),
                              label: Text(
                                'Share Story Card',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mock share triggered! Card image rendering to PNG (Layer 4+)... 📸'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color.fromRGBO(255, 255, 255, 0.7),
                                side: const BorderSide(
                                  color: Color.fromRGBO(255, 255, 255, 0.15),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => context.pop(),
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  fontSize: 16 * textScale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                      error: (err, stack) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64.0),
                        child: Center(
                          child: Text(
                            'Failed to generate debrief: $err',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),"""
content = content.replace(body_old, body_new)

with open('lib/features/debrief/presentation/screens/debrief_screen.dart', 'w') as f:
    f.write(content)
