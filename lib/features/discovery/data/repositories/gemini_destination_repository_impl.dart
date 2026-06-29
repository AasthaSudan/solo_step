import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/destination.dart';
import '../../domain/repositories/destination_repository.dart';

class GeminiDestinationRepositoryImpl implements DestinationRepository {
  final FirebaseFirestore _firestore;

  GeminiDestinationRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Destination>> generateDestinations(String uid) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userProfile = userDoc.exists && userDoc.data() != null
          ? userDoc.data()!
          : {
              'budget': 'medium',
              'interests': ['sightseeing', 'culture', 'food'],
              'experienceLevel': 'first_timer'
            };

      final prompt = '''
You are an expert travel planner. Recommend exactly 5 personalized travel destinations for a user based on this profile:
${jsonEncode(userProfile)}

Return exactly 5 destinations as structured JSON.
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
            'safetyNote'
          ],
        ),
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'destinations': schema,
            },
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

      return destinationsData.map((d) {
        final destMap = d as Map<String, dynamic>;
        return Destination(
          name: destMap['name'] as String,
          tagline: destMap['tagline'] as String,
          dailyBudgetEstimate: (destMap['dailyBudgetEstimate'] as num).toDouble(),
          highlights: (destMap['highlights'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
          safetyNote: destMap['safetyNote'] as String,
        );
      }).toList();
    } catch (e) {
      print('Error calling generateDestinations: $e');
      rethrow;
    }
  }
}
