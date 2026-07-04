import '../entities/itinerary.dart';

abstract interface class ItineraryRepository {
  Future<Itinerary> generateItinerary(String destinationName);
  Future<Itinerary> replanItinerary(Itinerary currentItinerary, String reason);
  Future<void> saveTrip(String uid, String tripId, String destinationName, Itinerary itinerary, {DateTime? startDate});
  Future<Itinerary?> getTripItinerary(String uid, String tripId);
}
