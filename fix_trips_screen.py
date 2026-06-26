import re

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'r') as f:
    content = f.read()

# Fix the build signatures
content = content.replace("Widget build(BuildContext context, WidgetRef ref) {", "Widget build(BuildContext context) {")
# Put the WidgetRef ref back only for TripsScreen
content = content.replace("class TripsScreen extends ConsumerWidget {\n  const TripsScreen({super.key});\n\n  void _openTrip", "class TripsScreen extends ConsumerWidget {\n  const TripsScreen({super.key});\n\n  void _openTrip")

build_old = """  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 700;
    final tripsAsync = ref.watch(tripsProvider);"""

build_new = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final size = MediaQuery.of(context).size;
    final bool isTablet = size.width >= 700;
    final tripsAsync = ref.watch(tripsProvider);"""
content = content.replace(build_old, build_new)

# Clean up _dummyTrips
dummy_trips_pattern = re.compile(r"const List<_TripItem> _dummyTrips = \[.*?\];\n\n", re.DOTALL)
content = dummy_trips_pattern.sub("", content)

# I also missed _TripStatus to TripStatus in _TripCard _varianceColor
content = content.replace("_TripStatus.completed", "TripStatus.completed")
content = content.replace("_TripStatus.active", "TripStatus.active")
content = content.replace("_TripStatus.planning", "TripStatus.planning")

with open('lib/features/archive/presentation/screens/trips_screen.dart', 'w') as f:
    f.write(content)
