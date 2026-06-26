import 'package:flutter/material.dart';

/// Renders a matching skeleton card layout during destination generation.
/// Uses a custom opacity animation to create a native pulsing shimmer effect.
class DestinationCardSkeleton extends StatefulWidget {
  const DestinationCardSkeleton({super.key});

  @override
  State<DestinationCardSkeleton> createState() =>
      _DestinationCardSkeletonState();
}

class _DestinationCardSkeletonState extends State<DestinationCardSkeleton>
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

    _alphaAnimation = Tween<double>(
      begin: 38,
      end: 102,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio:
          0.76, // Match the exact aspect ratio of the real DestinationCard
      child: AnimatedBuilder(
        animation: _alphaAnimation,
        builder: (context, child) {
          final Color shimmerColor = Colors.white.withAlpha(
            _alphaAnimation.value.round(),
          );
          final Color indicatorShimmerColor = const Color(
            0xFFC77DFF,
          ).withAlpha(_alphaAnimation.value.round());

          return Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.08),
                width: 1.5,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
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
                            // Top row: Budget indicator & status skeleton
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Budget tier tag
                                Container(
                                  width: 80,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: indicatorShimmerColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                // Small icon
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: shimmerColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Destination Name
                            Container(
                              width: 180,
                              height: 28,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Tagline
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 140,
                              height: 16,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Highlights Title
                            Container(
                              width: 100,
                              height: 18,
                              decoration: BoxDecoration(
                                color: shimmerColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Highlights lines (4 items)
                            ...List.generate(4, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: indicatorShimmerColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 120 + (index * 20.0),
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: shimmerColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),

                        // Safety Alert Banner at the bottom
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.05),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: indicatorShimmerColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: shimmerColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 120,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: shimmerColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
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
          );
        },
      ),
    );
  }
}
