import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/itinerary_repository.dart';

class GeminiItineraryRepositoryImpl implements ItineraryRepository {
  final FirebaseFirestore _firestore;

  GeminiItineraryRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Itinerary> generateItinerary(String destinationName) async {
    return _generateWithRetry(destinationName, 1);
  }

  Future<Itinerary> _generateWithRetry(String destinationName, int retriesLeft) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final prompt = '''
You are an expert, protective local guide and travel planner for a solo female traveler.
Create a detailed, hyper-specific day-by-day itinerary for a trip to $destinationName.
CRITICAL INSTRUCTIONS:
1. NO GENERIC ADVICE. You must provide EXACT names of businesses (e.g. "Zostel Delhi", "Roshan Di Kulfi").
2. For EVERY activity, you MUST provide explicit, step-by-step 'transitInstructions' (e.g., "Take Yellow Line metro to Rajiv Chowk, exit gate 5, walk 2 mins").
3. Provide a 'googleMapsQuery' string for every activity and stay (e.g., "Zostel+Delhi", "Red+Fort+New+Delhi").
4. Make sure every single activity has a realistic "category" (sightseeing, food, transport, stay, activity) and a numerical "estimatedCost" in INR.
Return the itinerary as structured JSON.
''';

      final schema = Schema.object(
        properties: {
          'days': Schema.array(
            items: Schema.object(
              properties: {
                'dayNumber': Schema.integer(),
                'activities': Schema.array(
                  items: Schema.object(
                    properties: {
                      'time': Schema.string(),
                      'title': Schema.string(),
                      'category': Schema.string(),
                      'estimatedCost': Schema.number(),
                      'notes': Schema.string(),
                      'transitInstructions': Schema.string(),
                      'googleMapsQuery': Schema.string(),
                    },
                    requiredProperties: ['time', 'title', 'category', 'estimatedCost', 'notes', 'transitInstructions', 'googleMapsQuery'],
                  ),
                ),
                'stayName': Schema.string(),
                'stayCost': Schema.number(),
                'stayMapsQuery': Schema.string(),
                'foodSuggestions': Schema.array(items: Schema.string()),
              },
              requiredProperties: ['dayNumber', 'activities', 'stayName', 'stayCost', 'stayMapsQuery', 'foodSuggestions'],
            ),
          ),
        },
        requiredProperties: ['days'],
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final data = jsonDecode(response.text!) as Map<String, dynamic>;
      final itinerary = Itinerary.fromMap(data);

      // Validate that all activities have category and estimatedCost
      bool isValid = true;
      for (final day in itinerary.days) {
        for (final activity in day.activities) {
          if (activity.category.isEmpty || activity.estimatedCost < 0.0) {
            isValid = false;
            break;
          }
        }
        if (!isValid) break;
      }

      if (!isValid) {
        if (retriesLeft > 0) {
          print('Validation failed: missing category or cost. Retrying...');
          return _generateWithRetry(destinationName, retriesLeft - 1);
        } else {
          throw Exception('Validation failed: Some activities are missing category or estimatedCost after retries.');
        }
      }

      return itinerary;
    } catch (e) {
      print('Error generating itinerary: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTrip(String uid, String tripId, String destinationName, Itinerary itinerary) async {
    try {
      final docRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
      
      final tripData = {
        'id': tripId,
        'destinationName': destinationName,
        'itinerary': itinerary.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };

      await docRef.set(tripData);
    } catch (e) {
      print('Error saving trip: $e');
      rethrow;
    }
  }
}
