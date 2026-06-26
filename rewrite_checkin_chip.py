import re

with open('lib/features/return_signal/presentation/widgets/checkin_chip.dart', 'r') as f:
    content = f.read()

# 1. Imports
imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/check_in_provider.dart';"""
content = re.sub(r"import 'package:flutter/material.dart';", imports, content)

# 2. Convert StatefulWidget to ConsumerStatefulWidget
content = content.replace("class CheckinChip extends StatefulWidget {", "class CheckinChip extends ConsumerStatefulWidget {")
content = content.replace("State<CheckinChip> createState() => _CheckinChipState();", "ConsumerState<CheckinChip> createState() => _CheckinChipState();")
content = content.replace("class _CheckinChipState extends State<CheckinChip> {", "class _CheckinChipState extends ConsumerState<CheckinChip> {")

# 3. Remove _isArmed state variable
content = content.replace("  bool _isArmed = false;\n", "")

# 4. Modify build method to check provider state
old_build = """  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return AnimatedContainer("""

new_build = """  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final checkInState = ref.watch(checkInProvider);
    final isArmed = checkInState.checkIn?.activityName == widget.activityLabel;
    // Use the provider's returnBy if armed, else the local one
    final displayTime = isArmed ? TimeOfDay.fromDateTime(checkInState.checkIn!.returnBy) : _returnBy;
    final isLoading = checkInState.isLoading && checkInState.checkIn?.activityName == widget.activityLabel;

    return AnimatedContainer("""
content = content.replace(old_build, new_build)

# Replace _isArmed with isArmed
content = content.replace("_isArmed", "isArmed")

# Change display of time
content = content.replace("_formatTime(_returnBy)", "_formatTime(displayTime)")

# 5. Arm logic
arm_old = """            // Arm Button
            InkWell(
              onTap: () {
                setState(() {
                  isArmed = true;
                });
              },"""
arm_new = """            // Arm Button
            InkWell(
              onTap: () {
                final now = DateTime.now();
                final target = DateTime(now.year, now.month, now.day, _returnBy.hour, _returnBy.minute);
                Duration diff = target.difference(now);
                if (diff.isNegative) diff = diff + const Duration(days: 1); // Next day if time already passed
                ref.read(checkInProvider.notifier).arm(
                  tripId: 'mock_trip_1',
                  activityName: widget.activityLabel,
                  duration: diff,
                );
              },"""
content = content.replace(arm_old, arm_new)

# 6. Disarm / I'm back logic
disarm_old = """            // "I'm back" button
            InkWell(
              onTap: () {
                setState(() {
                  isArmed = false;
                });
              },"""
disarm_new = """            // "I'm back" button
            InkWell(
              onTap: () {
                ref.read(checkInProvider.notifier).imBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Welcome back! Check-in completed.')),
                );
              },"""
content = content.replace(disarm_old, disarm_new)

with open('lib/features/return_signal/presentation/widgets/checkin_chip.dart', 'w') as f:
    f.write(content)
