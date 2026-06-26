import 'package:flutter/material.dart';

/// Progress indicator for the onboarding flow.
/// Features a back button, step label, and an animated linear progress bar.
class OnboardingProgressIndicator extends StatelessWidget {
  final int currentStep; // 1-indexed (1 to 5)
  final int totalSteps;
  final VoidCallback? onBack;

  const OnboardingProgressIndicator({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    final double progress = currentStep / totalSteps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top navigation row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back Button (only shown if not the first step)
              Opacity(
                opacity: currentStep > 1 ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: currentStep <= 1,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: onBack,
                    tooltip: 'Back',
                  ),
                ),
              ),
              
              // Step counter text
              Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(
                  color: const Color(0xFFE0AAFF),
                  fontSize: 14 * textScaleFactor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              
              // Empty spacer to balance the back button
              const SizedBox(width: 48),
            ],
          ),
        ),
        
        // Progress bar container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
          child: Stack(
            children: [
              // Track
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Animated Indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: constraints.maxWidth * progress,
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
                          color: const Color.fromRGBO(199, 125, 255, 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
