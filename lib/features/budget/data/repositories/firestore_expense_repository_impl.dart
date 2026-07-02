import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/expense.dart' as domain;
import '../../domain/entities/budget_summary.dart';
import '../../domain/repositories/expense_repository.dart';

class FirestoreExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // These will be calculated dynamically based on trip document and expenses.
  static const int _estimatedToDate = 0;

  FirestoreExpenseRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid {
    return _auth.currentUser?.uid;
  }

  CollectionReference<Map<String, dynamic>>? _expensesRef(String tripId) {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId)
        .collection('expenses');
  }

  @override
  Future<void> logExpense(domain.Expense e) async {
    try {
      final ref = _expensesRef(e.tripId);
      if (ref == null) return;
      final docRef = ref.doc(e.id);
      
      // Ensure it is marked as synced since we are writing directly to Firestore
      final expenseToSave = e.copyWith(synced: true);
      
      await docRef.set(expenseToSave.toMap());
    } catch (err) {
      debugPrint('Error logging expense to Firestore: $err');
      // Firestore SDK automatically queues writes while offline and retries them,
      // so this will only throw on serious permission/validation errors.
      rethrow;
    }
  }

  @override
  Stream<List<domain.Expense>> watchExpenses(String tripId) {
    final ref = _expensesRef(tripId);
    if (ref == null) return const Stream.empty();
    
    return ref
        .orderBy('spentAt', descending: true)
        .snapshots(includeMetadataChanges: true) // Allow local cache updates to emit immediately
        .map((snapshot) {
      return snapshot.docs.map((doc) => domain.Expense.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<BudgetSummary> summaryFor(String tripId) async {
    try {
      final uid = _uid;
      if (uid == null) throw Exception('User not authenticated');
      
      final tripRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
      final tripSnap = await tripRef.get(const GetOptions(source: Source.serverAndCache));
      
      int totalBudget = 0;
      int days = 1;
      
      if (tripSnap.exists) {
        final data = tripSnap.data();
        totalBudget = data?['totalBudgetInr'] as int? ?? 0;
        
        final itinerary = data?['itinerary'] as Map<String, dynamic>?;
        if (itinerary != null) {
          final daysList = itinerary['days'] as List?;
          days = daysList?.length ?? 1;
        }
      }
      
      final dailyTarget = days > 0 ? (totalBudget / days).round() : 0;
      
      final ref = _expensesRef(tripId);
      if (ref == null) throw Exception('User not authenticated');
      
      final snapshot = await ref.get(const GetOptions(source: Source.serverAndCache));
      
      int totalSpent = 0;
      for (var doc in snapshot.docs) {
        final expense = domain.Expense.fromMap(doc.data(), doc.id);
        totalSpent += expense.amountInr;
      }

      return BudgetSummary(
        totalBudgetInr: totalBudget,
        durationDays: days,
        dailyTargetInr: dailyTarget,
        spentInr: totalSpent,
        estimatedToDateInr: _estimatedToDate,
      );
    } catch (err) {
      debugPrint('Error calculating summary: $err');
      // Fallback
      return const BudgetSummary(
        totalBudgetInr: 0,
        durationDays: 1,
        dailyTargetInr: 0,
        spentInr: 0,
        estimatedToDateInr: 0,
      );
    }
  }

  @override
  Future<void> setTripBudget(String tripId, int budgetInr) async {
    final uid = _uid;
    if (uid == null) return;
    
    final tripRef = _firestore.collection('users').doc(uid).collection('trips').doc(tripId);
    await tripRef.set({
      'totalBudgetInr': budgetInr,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> syncPending() async {
    // No-op. Firestore SDK natively handles offline sync in the background automatically.
    // There is no need to manually implement a sync loop!
  }
}
