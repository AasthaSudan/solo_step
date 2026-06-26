import '../entities/check_in.dart';

abstract interface class CheckInRepository {
  Future<CheckIn> armCheckIn({
    required String tripId,
    required String activityName,
    required DateTime returnBy,
    required int graceMinutes,
  });

  Future<void> disarmCheckIn(String checkInId);

  Future<void> completeCheckIn(String checkInId);
}
