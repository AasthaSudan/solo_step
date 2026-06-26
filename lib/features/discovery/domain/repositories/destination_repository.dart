import '../entities/destination.dart';

abstract interface class DestinationRepository {
  Future<List<Destination>> generateDestinations(String uid);
}
