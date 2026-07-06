import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/itinerary.dart';
import '../../domain/entities/packing_item.dart';
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
8. VERY IMPORTANT: For `searchLink`s:
- For accommodations, use direct search URLs (e.g., "https://www.booking.com/searchresults.html?ss=[Hotel+Name]").
- For foodOptions, ALWAYS use a Google Maps search URL (e.g., "https://www.google.com/maps/search/?api=1&query=[Restaurant+Name+Location]"). Do NOT use Zomato or Swiggy links.
- For transportOptions, use direct search URLs (e.g. MakeMyTrip, RedBus, or IRCTC).
9. Also provide exact `latitude` and `longitude` (as numbers) for every single activity to map it on an OpenStreetMap.
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
                      'latitude': Schema.number(),
                      'longitude': Schema.number(),
                      'transitInstructions': Schema.string(),
                      'googleMapsQuery': Schema.string(),
                      'imageUrl': Schema.string(nullable: true),
                      'bookingLink': Schema.string(nullable: true),
                    },
                    requiredProperties: ['time', 'title', 'category', 'estimatedCost', 'notes', 'transitInstructions', 'googleMapsQuery', 'latitude', 'longitude'],
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
          temperature: 0.9,
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
  Future<Itinerary> replanItinerary(Itinerary currentItinerary, String reason) async {
    return _replanWithRetry(currentItinerary, reason, 1);
  }

  Future<Itinerary> _replanWithRetry(Itinerary currentItinerary, String reason, int retriesLeft) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final currentJson = jsonEncode(currentItinerary.toMap());

      final prompt = '''
You are an expert travel planner. I have an existing JSON itinerary for a solo female traveler.
I need you to REWRITE this itinerary because: "$reason".

Current Itinerary:
$currentJson

CRITICAL INSTRUCTIONS:
1. You must return the updated itinerary in the exact same JSON schema as the input.
2. Only change the activities that make sense to change based on the reason. Keep the rest the same.
3. For new activities, follow the same rules: NO GENERIC ADVICE. Provide specific places, realistic costs, transit instructions, Google Maps queries, etc.
4. Keep the same number of days.
5. Provide exact `latitude` and `longitude` for any new activities.
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
                      'latitude': Schema.number(),
                      'longitude': Schema.number(),
                      'transitInstructions': Schema.string(),
                      'googleMapsQuery': Schema.string(),
                      'imageUrl': Schema.string(nullable: true),
                      'bookingLink': Schema.string(nullable: true),
                    },
                    requiredProperties: ['time', 'title', 'category', 'estimatedCost', 'notes', 'transitInstructions', 'googleMapsQuery', 'latitude', 'longitude'],
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
          temperature: 0.9,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final data = jsonDecode(response.text!) as Map<String, dynamic>;
      final itinerary = Itinerary.fromMap(data);

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
          return _replanWithRetry(currentItinerary, reason, retriesLeft - 1);
        } else {
          throw Exception('Validation failed: Some activities are missing category or estimatedCost after retries.');
        }
      }

      return itinerary;
    } catch (e) {
      print('Error replanning itinerary: $e');
      rethrow;
    }
  }

  @override
  Future<List<PackingItem>> generatePackingList(Itinerary itinerary) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY is missing in .env');
      }

      final itineraryJson = jsonEncode(itinerary.toMap());

      final prompt = '''
You are an expert travel assistant. I have an existing JSON itinerary for a solo female traveler.
I need you to generate a smart, highly personalized packing list based ONLY on this specific itinerary.

Itinerary:
$itineraryJson

INSTRUCTIONS:
1. Generate a comprehensive packing list categorized into groups (e.g., Clothing, Toiletries, Electronics, Documents, Safety).
2. Every item MUST have a specific, highly contextual "reason" that explicitly mentions a place or activity from the itinerary. 
   - DO NOT say: "To keep you warm." 
   - DO say: "To keep you warm during the evening boat ride on Day 2."
3. Think about cultural norms (e.g., modest clothing for temples) and practical needs based on the generated itinerary.
4. Return the result as a JSON array of objects.

Follow the exact schema provided.
''';

      final schema = Schema.array(
        items: Schema.object(
          properties: {
            'id': Schema.string(),
            'name': Schema.string(),
            'category': Schema.string(),
            'reason': Schema.string(),
          },
          requiredProperties: ['id', 'name', 'category', 'reason'],
        ),
      );

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: schema,
          temperature: 0.9,
        ),
      );

      final response = await model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Gemini did not return text.');
      }

      final dataList = jsonDecode(response.text!) as List<dynamic>;
      final packingList = dataList.map((data) => PackingItem.fromMap(data as Map<String, dynamic>)).toList();

      return packingList;
    } catch (e) {
      print('Error generating packing list: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveTrip(String uid, String tripId, String destinationName, Itinerary itinerary, {DateTime? startDate}) async {
    try {
      final docRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
      
      final tripData = {
        'id': tripId,
        'destinationName': destinationName,
        'itinerary': itinerary.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
      };
      
      if (startDate != null) {
        tripData['startDate'] = Timestamp.fromDate(startDate);
        final endDate = startDate.add(Duration(days: itinerary.days.length - 1));
        tripData['endDate'] = Timestamp.fromDate(endDate);
      }

      await docRef.set(tripData, SetOptions(merge: true));
      
      // Save to local Hive cache
      try {
        final box = Hive.box('itineraries');
        await box.put(tripId, jsonEncode(itinerary.toMap()));
      } catch (e) {
        print('Error caching to Hive: $e');
      }
      
    } catch (e) {
      print('Error saving trip: $e');
      rethrow;
    }
  }

  @override
  Future<Itinerary?> getTripItinerary(String uid, String tripId) async {
    try {
      // 1. Try local cache first for instant loading
      try {
        final box = Hive.box('itineraries');
        final cachedData = box.get(tripId);
        if (cachedData != null) {
          final decoded = jsonDecode(cachedData) as Map<String, dynamic>;
          return Itinerary.fromMap(decoded);
        }
      } catch (e) {
        print('Error reading from Hive cache: $e');
      }

      // 2. Fallback to Firestore
      final docRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
      // Use cache source first if offline
      final doc = await docRef.get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      
      final data = doc.data();
      if (data == null || !data.containsKey('itinerary')) return null;
      
      final itineraryData = data['itinerary'] as Map<String, dynamic>;
      final itinerary = Itinerary.fromMap(itineraryData);
      
      // Cache it for next time
      try {
        final box = Hive.box('itineraries');
        await box.put(tripId, jsonEncode(itineraryData));
      } catch (e) {}

      return itinerary;
    } catch (e) {
      print('Error getting trip itinerary: $e');
      return null;
    }
  }
}
