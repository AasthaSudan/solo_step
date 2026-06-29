import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';

final tripsProvider = StreamProvider<List<Trip>>((ref) {
  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  
  // In a fully auth-gated app, uid would never be null here, 
  // but we handle it safely.
  final uid = auth.currentUser?.uid;
  if (uid == null) {
    return Stream.value([]);
  }

  return firestore
      .collection('users')
      .doc(uid)
      .collection('trips')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();

      TripStatus status = TripStatus.planning;
      final statusStr = data['status'] as String? ?? 'planning';
      if (statusStr == 'active') status = TripStatus.active;
      if (statusStr == 'completed') status = TripStatus.completed;

      final itinerary = data['itinerary'] as Map<String, dynamic>?;
      final days = itinerary != null ? (itinerary['days'] as List?)?.length ?? 0 : 0;

      final debrief = data['debrief'] as Map<String, dynamic>?;
      final spent = debrief != null ? (debrief['totalSpentInr'] as int? ?? 0) : 0;
      final topCategory = debrief != null ? (debrief['topCategory'] as String? ?? 'None') : 'None';

      return Trip(
        id: doc.id,
        destinationName: data['destinationName'] as String? ?? 'Unknown',
        tagline: data['tagline'] as String? ?? '', // Could be extracted if saved during discovery
        dates: data['dates'] as String? ?? 'Dates TBD', // Fallback
        status: status,
        budget: data['totalBudgetInr'] as int? ?? 0,
        spent: spent,
        days: days,
        topCategory: topCategory,
      );
    }).toList();
  });
});
