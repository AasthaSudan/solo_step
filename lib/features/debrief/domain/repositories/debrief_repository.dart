abstract interface class DebriefRepository {
  Future<({String personality, List<String> traits, String caption})> fetchFlavor(String tripId);
}
