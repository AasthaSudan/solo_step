import re

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../debrief/domain/entities/debrief_card.dart';
import '../../domain/entities/trip.dart';
import '../providers/trips_provider.dart';"""
content = content.replace("import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';\nimport '../../../debrief/domain/entities/debrief_card.dart';", imports)

# Remove _TripStatus, extension on _TripStatus, _TripItem, _dummyTrips
# Wait, I need to keep the extension on TripStatus but rename it from _TripStatus to TripStatus
content = content.replace("enum _TripStatus { planning, active, completed }", "")
content = content.replace("extension on _TripStatus {", "extension on TripStatus {")
content = content.replace("_TripStatus.planning", "TripStatus.planning")
content = content.replace("_TripStatus.active", "TripStatus.active")
content = content.replace("_TripStatus.completed", "TripStatus.completed")

# Remove _TripItem and _dummyTrips definitions
trip_item_pattern = re.compile(r"class _TripItem \{.*?\};\n", re.DOTALL)
content = trip_item_pattern.sub("", content)
content = content.replace("List<_TripItem> _tripsForStatus(_TripStatus status) {\n    return _dummyTrips.where((trip) => trip.status == status).toList();\n  }", "")

# Change TripsScreen to ConsumerWidget
content = content.replace("class TripsScreen extends StatelessWidget {", "class TripsScreen extends ConsumerWidget {")
content = content.replace("Widget build(BuildContext context) {", "Widget build(BuildContext context, WidgetRef ref) {")

# Update _openTrip signature
content = content.replace("void _openTrip(BuildContext context, _TripItem trip) {", "void _openTrip(BuildContext context, Trip trip) {")

# Rewrite the build method to watch tripsProvider and handle async states
build_old = """    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 700;

    return Scaffold("""
build_new = """    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 700;
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold("""
content = content.replace(build_old, build_new)

# The core slivers
slivers_old = """                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _TripStatus.values.map((status) {
                          final trips = _tripsForStatus(status);
                          return _StatusSection(
                            status: status,
                            trips: trips,
                            textScale: textScale,
                            onTap: (trip) => _openTrip(context, trip),
                          );
                        }).toList(),
                      ),
                    ),
                  ),"""

slivers_new = """                  tripsAsync.when(
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
                  ),"""
content = content.replace(slivers_old, slivers_new)

# Update Wrap in the SliverToBoxAdapter
wrap_old = """                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _TripStatus.values.map((status) {
                              return _StatusSummaryChip(
                                label:
                                    '${status.label} ${_tripsForStatus(status).length}',
                                color: status.color,
                                icon: status.icon,
                              );
                            }).toList(),
                          ),"""
wrap_new = """                          tripsAsync.maybeWhen(
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
                          ),"""
content = content.replace(wrap_old, wrap_new)

# Update class signatures for _TripItem -> Trip and _TripStatus -> TripStatus
content = content.replace("final _TripStatus status;", "final TripStatus status;")
content = content.replace("final List<_TripItem> trips;", "final List<Trip> trips;")
content = content.replace("final void Function(_TripItem trip) onTap;", "final void Function(Trip trip) onTap;")
content = content.replace("final _TripItem trip;", "final Trip trip;")

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'w') as f:
    f.write(content)
