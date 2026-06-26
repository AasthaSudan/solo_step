import '../../domain/entities/check_in.dart';
import '../../domain/repositories/check_in_repository.dart';

class FakeCheckInRepositoryImpl implements CheckInRepository {
  @override
  Future<CheckIn> armCheckIn({
    required String tripId,
    required String activityName,
    required DateTime returnBy,
    required int graceMinutes,
  }) async {
    // Simulate slight network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    return CheckIn(
      id: 'fake_checkin_${DateTime.now().millisecondsSinceEpoch}',
      activityName: activityName,
      returnBy: returnBy,
      graceMinutes: graceMinutes,
      status: CheckInStatus.active,
      lastKnownLocation: (lat: 10.0889, lng: 77.0595), // Munnar fake coordinates
    );
  }

  @override
  Future<void> disarmCheckIn(String checkInId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> completeCheckIn(String checkInId) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
