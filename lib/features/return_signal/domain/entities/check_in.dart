/// Lifecycle status of a single Return Signal check-in.
enum CheckInStatus {
  /// Check-in is armed; user has not yet tapped "I'm back".
  active,

  /// User tapped "I'm back" before the deadline. No SMS sent.
  completed,

  /// Server detected the deadline + grace was missed and sent an SMS.
  alertSent,
}

/// Domain entity representing a single Return Signal check-in.
class CheckIn {
  final String id;
  final String activityName;

  /// When the user is expected to return / complete the activity.
  final DateTime returnBy;

  /// Minutes added on top of [returnBy] before the scheduled function fires.
  final int graceMinutes;

  final CheckInStatus status;

  /// Last-known GPS coordinates captured when the check-in was armed.
  final ({double lat, double lng})? lastKnownLocation;

  const CheckIn({
    required this.id,
    required this.activityName,
    required this.returnBy,
    required this.graceMinutes,
    required this.status,
    this.lastKnownLocation,
  });

  DateTime get deadline => returnBy.add(Duration(minutes: graceMinutes));

  bool get isActive => status == CheckInStatus.active;
}
