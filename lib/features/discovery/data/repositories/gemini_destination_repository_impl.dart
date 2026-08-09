import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/destination_image.dart';
import '../demo/demo_destinations.dart';
import '../../domain/entities/destination.dart';
import '../../domain/repositories/destination_repository.dart';

Future<String> _fetchWikipediaImage(String destinationName) async {
  // First, check if we have a curated, high-quality Unsplash image for this destination
  final curatedUrl = destinationImageUrl(destinationName);
  if (curatedUrl.contains('unsplash.com')) {
    return curatedUrl;
  }

  // If no curated image, try fetching from Wikipedia
  try {
    final name = Uri.encodeComponent(destinationName.split(',').first.trim());
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$name',
    );
    final request = await HttpClient().getUrl(url);
    final response = await request.close();
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);
      if (data['originalimage'] != null &&
          data['originalimage']['source'] != null) {
        return data['originalimage']['source'] as String;
      }
    }
  } catch (_) {}

  // fallback if Wikipedia fails or has no image
  final encodedName = Uri.encodeComponent('$destinationName,travel');
  return 'https://loremflickr.com/1200/800/$encodedName/all';
}

class GeminiDestinationRepositoryImpl implements DestinationRepository {
  final FirebaseFirestore _firestore;

  GeminiDestinationRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Destination>> generateDestinations(String uid) async {
    try {
      final apiKey = AppConfig.instance.geminiApiKeyOrNull;
      if (apiKey == null) {
        throw const GeminiApiKeyMissingException();
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userProfile = userDoc.exists && userDoc.data() != null
          ? Map<String, dynamic>.from(userDoc.data()!)
          : <String, dynamic>{
              'budget': 'medium',
              'interests': ['sightseeing', 'culture', 'food'],
              'experienceLevel': 'first_timer',
            };

      // Remove Firestore specific objects like Timestamps to avoid jsonEncode exception
      userProfile.removeWhere((key, value) => value is Timestamp);

      if (isInternshipDemoProfile(userProfile)) {
        return demoDestinations;
      }

      final prompt =
          '''
You are an expert travel planner specializing in Indian tourism. Recommend exactly 5 personalized travel destinations WITHIN INDIA for a user based on this profile:
${jsonEncode(userProfile)}

Return exactly 5 destinations as structured JSON. All destinations MUST be in India (e.g., Manali, Goa, Jaipur, Kerala, etc.). Each destination must have 3 unique highlights that are specifically about that place; never reuse generic highlights across destinations.
The dailyBudgetEstimate must be a realistic Indian solo-traveller estimate in INR, including accommodation, meals and local transport, between 1200 and 15000. Never return a two-digit value.
''';

      final schema = Schema.array(
        description: 'List of destinations',
        items: Schema.object(
          properties: {
            'name': Schema.string(),
            'tagline': Schema.string(),
            'dailyBudgetEstimate': Schema.number(),
            'highlights': Schema.array(items: Schema.string()),
            'safetyNote': Schema.string(),
          },
          requiredProperties: [
            'name',
            'tagline',
            'dailyBudgetEstimate',
            'highlights',
            'safetyNote',
          ],
        ),
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {'destinations': schema},
            requiredProperties: ['destinations'],
          ),
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final data = jsonDecode(response.text!) as Map<String, dynamic>;
      final destinationsData = data['destinations'] as List<dynamic>;

      final futures = destinationsData.map((d) async {
        final destMap = d as Map<String, dynamic>;
        final name = destMap['name'] as String;
        final generatedHighlights = (destMap['highlights'] as List<dynamic>)
            .map((e) => e as String)
            .where((e) => e.trim().isNotEmpty)
            .toList();

        final imageUrl = await _fetchWikipediaImage(name);

        return Destination(
          name: name,
          tagline: destMap['tagline'] as String,
          dailyBudgetEstimate: normalizedDailyBudget(
            destMap['name'] as String,
            destMap['dailyBudgetEstimate'] as num,
          ),
          highlights: generatedHighlights.isEmpty
              ? destinationFallbackHighlights(name)
              : generatedHighlights,
          safetyNote: destMap['safetyNote'] as String,
          imageUrl: imageUrl,
        );
      });

      return await Future.wait(futures);
    } catch (e) {
      print('Error calling generateDestinations: $e');
      rethrow;
    }
  }
}
