import 'package:flutter/material.dart';

/// Renders a skeleton card mimicking an expandable DayCard during itinerary generation.
/// Uses a custom pulsing animation to avoid deprecation warnings.
class DayCardSkeleton extends StatefulWidget {
  const DayCardSkeleton({super.key});

  @override
  State<DayCardSkeleton> createState() => _DayCardSkeletonState();
}

class _DayCardSkeletonState extends State<DayCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _alphaAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _alphaAnimation = Tween<double>(begin: 38, end: 102).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _alphaAnimation,
      builder: (context, child) {
        final Color shimmerColor = Colors.grey.shade400.withAlpha((_alphaAnimation.value * 2.5).round().clamp(0, 255));
        final Color indicatorShimmerColor = const Color(0xFF2C3E50).withAlpha((_alphaAnimation.value * 2.5).round().clamp(0, 255));

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Day X" text box
                      Container(
                        width: 80,
                        height: 20,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Lodging info row
                      Container(
                        width: 180,
                        height: 14,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  // Chevron indicator
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: indicatorShimmerColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 20),

              // Activity 1 skeleton
              _buildActivitySkeleton(shimmerColor, indicatorShimmerColor),
              const SizedBox(height: 16),
              
              // Activity 2 skeleton
              _buildActivitySkeleton(shimmerColor, indicatorShimmerColor),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivitySkeleton(Color shimmerColor, Color indicatorShimmerColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time indicator box
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: indicatorShimmerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: shimmerColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Description block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // Category tag
              Container(
                width: 90,
                height: 20,
                decoration: BoxDecoration(
                  color: shimmerColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
