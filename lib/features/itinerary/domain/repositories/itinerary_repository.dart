import '../entities/itinerary.dart';

abstract interface class ItineraryRepository {
  Future<Itinerary> generateItinerary(String destinationName);
}
