import '../../domain/repositories/debrief_repository.dart';

class FakeDebriefRepositoryImpl implements DebriefRepository {
  @override
  Future<({String personality, List<String> traits, String caption})> fetchFlavor(String tripId) async {
    await Future.delayed(const Duration(seconds: 2));
    return (
      personality: 'Budget Adventurer',
      traits: ['Street Food Scout', 'Early Riser', 'Offbeat Trails'],
      caption: 'Found the hidden tea gardens of Munnar and saved some rupees along the way!',
    );
  }
}
