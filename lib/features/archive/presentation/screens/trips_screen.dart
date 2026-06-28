import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../debrief/domain/entities/debrief_card.dart';
import '../../domain/entities/trip.dart';
import '../providers/trips_provider.dart';



extension on TripStatus {
  String get label {
    switch (this) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.active:
        return 'Active';
      case TripStatus.completed:
        return 'Completed';
    }
  }

  String get sectionSubtitle {
    switch (this) {
      case TripStatus.planning:
        return 'Trips you are shaping now';
      case TripStatus.active:
        return 'Trips currently in motion';
      case TripStatus.completed:
        return 'Trips already wrapped';
    }
  }

  Color get color {
    switch (this) {
      case TripStatus.planning:
        return const Color(0xFF4285F4);
      case TripStatus.active:
        return const Color(0xFFC77DFF);
      case TripStatus.completed:
        return const Color(0xFF34A853);
    }
  }

  IconData get icon {
    switch (this) {
      case TripStatus.planning:
        return Icons.route_rounded;
      case TripStatus.active:
        return Icons.bolt_rounded;
      case TripStatus.completed:
        return Icons.celebration_rounded;
    }
  }
}


class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key});

  

  void _openTrip(BuildContext context, Trip trip) {
    final encodedName = Uri.encodeComponent(trip.destinationName);
    switch (trip.status) {
      case TripStatus.active:
        context.go('/trips/active/$encodedName');
        return;
      case TripStatus.planning:
        context.go('/trips/itinerary/$encodedName');
        return;
      case TripStatus.completed:
        final savings = trip.budget - trip.spent;
        final card = DebriefCard(
          personality: savings >= 0 ? 'Budget Adventurer' : 'Bold Wanderer',
          traits: savings >= 0
              ? ['Street Food Scout', 'Route Planner', 'Early Riser']
              : ['Spontaneous Diner', 'Scenic Detours', 'Night Owl'],
          caption: savings >= 0
              ? 'Wrapped a trip with smart spending, strong check-ins, and plenty of local discoveries.'
              : 'Came home with bigger memories than budget, and a story worth sharing anyway.',
          savedVsEstimateInr: savings,
          totalSpentInr: trip.spent,
          daysCount: trip.days,
          topCategory: trip.topCategory,
        );

        context.go('/trips/debrief', extra: card);
        return;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 700;
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C20), Color(0xFF15102A), Color(0xFF2E1A47)],
            stops: [0.0, 0.42, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isTablet ? 1120 : double.infinity,
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF9D4EDD),
                                      Color(0xFFC77DFF),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF9D4EDD,
                                      ).withAlpha(55),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.card_travel_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trips',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24 * textScale,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Grouped by status with hardcoded Layer 1 data.',
                                      style: TextStyle(
                                        color: const Color.fromRGBO(
                                          255,
                                          255,
                                          255,
                                          0.6,
                                        ),
                                        fontSize: 13 * textScale,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          tripsAsync.maybeWhen(
                            data: (trips) => Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: TripStatus.values.map((status) {
                                final count = trips.where((t) => t.status == status).length;
                                return _StatusSummaryChip(
                                  label: '${status.label} $count',
                                  color: status.color,
                                  icon: status.icon,
                                );
                              }).toList(),
                            ),
                            orElse: () => const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  tripsAsync.when(
                    data: (trips) {
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            TripStatus.values.map((status) {
                              final statusTrips = trips.where((t) => t.status == status).toList();
                              return _StatusSection(
                                status: status,
                                trips: statusTrips,
                                textScale: textScale,
                                onTap: (trip) => _openTrip(context, trip),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                    error: (err, stack) => SliverFillRemaining(
                      child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusSummaryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(84)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final TripStatus status;
  final List<Trip> trips;
  final double textScale;
  final void Function(Trip trip) onTap;

  const _StatusSection({
    required this.status,
    required this.trips,
    required this.textScale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: status.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: status.color.withAlpha(90),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${trips.length}',
                style: TextStyle(
                  color: const Color.fromRGBO(255, 255, 255, 0.55),
                  fontSize: 13 * textScale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            status.sectionSubtitle,
            style: TextStyle(
              color: const Color.fromRGBO(255, 255, 255, 0.55),
              fontSize: 13 * textScale,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final bool useGrid = constraints.maxWidth >= 760;
              if (!useGrid) {
                return Column(
                  children: [
                    for (final trip in trips) ...[
                      _TripCard(
                        trip: trip,
                        textScale: textScale,
                        onTap: () => onTap(trip),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                );
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final trip in trips)
                    SizedBox(
                      width: (constraints.maxWidth - 16) / 2,
                      child: _TripCard(
                        trip: trip,
                        textScale: textScale,
                        onTap: () => onTap(trip),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final double textScale;
  final VoidCallback onTap;

  const _TripCard({
    required this.trip,
    required this.textScale,
    required this.onTap,
  });

  String get _varianceLabel {
    final variance = trip.budget - trip.spent;
    if (variance >= 0) {
      return '₹$variance saved';
    }
    return '₹${variance.abs()} over';
  }

  Color get _varianceColor {
    if (trip.status != TripStatus.completed) {
      return trip.status.color;
    }
    return trip.budget - trip.spent >= 0
        ? const Color(0xFF34A853)
        : const Color(0xFFFF6D60);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = trip.status.color.withAlpha(70);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromRGBO(255, 255, 255, 0.05),
                const Color.fromRGBO(255, 255, 255, 0.025),
              ],
            ),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: trip.status.color.withAlpha(16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusChip(
                      label: trip.status.label,
                      color: trip.status.color,
                      icon: trip.status.icon,
                    ),
                    const Spacer(),
                    Text(
                      trip.dates,
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.45),
                        fontSize: 11 * textScale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  trip.destinationName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * textScale,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trip.tagline,
                  style: TextStyle(
                    color: const Color.fromRGBO(255, 255, 255, 0.62),
                    fontSize: 13 * textScale,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      label: '${trip.days} days',
                      color: const Color(0xFF4285F4),
                    ),
                    _InfoChip(
                      label: trip.status == TripStatus.active
                          ? 'Spent ₹${trip.spent} / ₹${trip.budget}'
                          : trip.status == TripStatus.planning
                          ? 'Budget ₹${trip.budget}'
                          : _varianceLabel,
                      color: _varianceColor,
                    ),
                    _InfoChip(
                      label: 'Top: ${trip.topCategory}',
                      color: const Color(0xFFC77DFF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withAlpha(225),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
