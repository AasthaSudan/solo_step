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
You are an expert, protective local guide and travel planner for a solo female traveler in India.
Create a detailed, hyper-specific day-by-day itinerary for a trip to $destinationName.
CRITICAL INSTRUCTIONS:
1. NO GENERIC ADVICE. You must provide EXACT names of businesses (e.g. "Zostel Delhi", "Roshan Di Kulfi").
2. For EVERY activity, you MUST provide explicit, step-by-step 'transitInstructions' (e.g., "Take Yellow Line metro to Rajiv Chowk, exit gate 5, walk 2 mins").
3. Provide a 'googleMapsQuery' string for every activity and stay (e.g., "Zostel+Delhi", "Red+Fort+New+Delhi").
4. Provide a 'bookingLink' URL for every stay, activity, and food if applicable (e.g. MakeMyTrip, Agoda, Zomato, or official site URL).
5. Provide an 'imageUrl' for every stay, activity, and food pointing to a public Wikimedia Commons image URL of the location (or a descriptive placeholder URL).
6. Make sure every single activity has a realistic "category" (sightseeing, food, transport, stay, activity) and a numerical "estimatedCost" in INR.
7. Provide a list of 5-7 specific "accommodations" (mix of budget hostels, mid-range, luxury), 5-7 specific "foodOptions" (restaurants, cafes), and 3-5 "transportOptions" (flights, trains, or overnight buses) relevant to the trip. 
8. VERY IMPORTANT: For the `searchLink` in accommodations, foodOptions, and transportOptions, DO NOT just link to a homepage like "booking.com". You MUST generate a direct search URL with query parameters (e.g., "https://www.booking.com/searchresults.html?ss=Zostel+Manali" or "https://www.zomato.com/search?q=Cafe+1947").
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
                      'imageUrl': Schema.string(nullable: true),
                      'bookingLink': Schema.string(nullable: true),
                    },
                    requiredProperties: ['time', 'title', 'category', 'estimatedCost', 'notes', 'transitInstructions', 'googleMapsQuery'],
                  ),
                ),
                'stayName': Schema.string(),
                'stayCost': Schema.number(),
                'stayMapsQuery': Schema.string(),
                'stayImageUrl': Schema.string(nullable: true),
                'stayBookingLink': Schema.string(nullable: true),
                'foodSuggestions': Schema.array(items: Schema.string()),
              },
              requiredProperties: ['dayNumber', 'activities', 'stayName', 'stayCost', 'stayMapsQuery', 'foodSuggestions'],
            ),
          ),
          'accommodations': Schema.array(
            items: Schema.object(
              properties: {
                'id': Schema.string(),
                'type': Schema.string(),
                'name': Schema.string(),
                'description': Schema.string(),
                'estimatedCostInr': Schema.integer(),
                'searchLink': Schema.string(),
              },
              requiredProperties: ['id', 'type', 'name', 'description', 'estimatedCostInr', 'searchLink'],
            ),
          ),
          'foodOptions': Schema.array(
            items: Schema.object(
              properties: {
                'id': Schema.string(),
                'type': Schema.string(),
                'name': Schema.string(),
                'description': Schema.string(),
                'estimatedCostInr': Schema.integer(),
                'searchLink': Schema.string(),
              },
              requiredProperties: ['id', 'type', 'name', 'description', 'estimatedCostInr', 'searchLink'],
            ),
          ),
          'transportOptions': Schema.array(
            items: Schema.object(
              properties: {
                'id': Schema.string(),
                'type': Schema.string(),
                'name': Schema.string(),
                'description': Schema.string(),
                'estimatedCostInr': Schema.integer(),
                'searchLink': Schema.string(),
              },
              requiredProperties: ['id', 'type', 'name', 'description', 'estimatedCostInr', 'searchLink'],
            ),
          ),
        },
        requiredProperties: ['days', 'accommodations', 'foodOptions', 'transportOptions'],
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

  @override
  Future<Itinerary?> getTripItinerary(String uid, String tripId) async {
    try {
      final docRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
      final doc = await docRef.get();
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null || !data.containsKey('itinerary')) return null;
      
      return Itinerary.fromMap(data['itinerary'] as Map<String, dynamic>);
    } catch (e) {
      print('Error getting trip itinerary: $e');
      return null;
    }
  }
}
