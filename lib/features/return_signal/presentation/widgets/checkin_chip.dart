import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/check_in_provider.dart';

/// A compact pill-shaped chip displayed next to an itinerary activity.
///
/// Under Layer 1 (UI-only), it pre-fills an AI-suggested return-by time
/// computed from `suggestedReturnMinutes`. The time is editable via a time picker
/// when unarmed. Tapping "Arm" toggles the armed status, showing a shield icon and
/// an "I'm back" disarm button.
class CheckinChip extends ConsumerStatefulWidget {
  /// Display label for the chip (typically the activity title).
  final String activityLabel;

  /// Pre-filled suggested return-by offset in minutes (from now).
  final int suggestedReturnMinutes;

  const CheckinChip({
    super.key,
    required this.activityLabel,
    this.suggestedReturnMinutes = 90,
  });

  @override
  ConsumerState<CheckinChip> createState() => _CheckinChipState();
}

class _CheckinChipState extends ConsumerState<CheckinChip> {
  late TimeOfDay _returnBy;

  @override
  void initState() {
    super.initState();
    _calculateSuggestedTime();
  }

  @override
  void didUpdateWidget(covariant CheckinChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestedReturnMinutes != widget.suggestedReturnMinutes) {
      _calculateSuggestedTime();
    }
  }

  void _calculateSuggestedTime() {
    final now = DateTime.now();
    final returnTime = now.add(Duration(minutes: widget.suggestedReturnMinutes));
    _returnBy = TimeOfDay.fromDateTime(returnTime);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _returnBy,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC77DFF),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _returnBy = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final checkInState = ref.watch(checkInProvider);
    final isArmed = checkInState.checkIn?.activityName == widget.activityLabel;
    // Use the provider's returnBy if armed, else the local one
    final displayTime = isArmed ? TimeOfDay.fromDateTime(checkInState.checkIn!.returnBy) : _returnBy;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isArmed
            ? const Color.fromRGBO(234, 67, 53, 0.1) // 10% red
            : const Color.fromRGBO(199, 125, 255, 0.08), // ~8% purple
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isArmed
              ? const Color.fromRGBO(234, 67, 53, 0.35)
              : const Color.fromRGBO(199, 125, 255, 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isArmed) ...[
            // Time selection area (only clickable when unarmed)
            InkWell(
              onTap: () => _selectTime(context),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_filled_rounded,
                      size: 14,
                      color: Color(0xFFC77DFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back by ${_formatTime(displayTime)}',
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.85),
                        fontSize: 12 * textScale,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.edit_rounded,
                      size: 11,
                      color: Color.fromRGBO(255, 255, 255, 0.4),
                    ),
                  ],
                ),
              ),
            ),
            // Vertical Divider
            Container(
              height: 18,
              width: 1,
              color: const Color.fromRGBO(199, 125, 255, 0.2),
            ),
            // Arm Button
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
              },
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: Color(0xFFC77DFF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Arm',
                      style: TextStyle(
                        color: const Color(0xFFC77DFF),
                        fontSize: 12 * textScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Armed State Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield,
                    size: 14,
                    color: Color(0xFFFF6D60),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Armed until ${_formatTime(displayTime)}',
                    style: TextStyle(
                      color: const Color(0xFFFF6D60),
                      fontSize: 12 * textScale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // "I'm back" button
            InkWell(
              onTap: () {
                ref.read(checkInProvider.notifier).imBack();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Welcome back! Check-in completed.')),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(234, 67, 53, 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "I'm back",
                  style: TextStyle(
                    color: const Color(0xFFFF6D60),
                    fontSize: 11 * textScale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
