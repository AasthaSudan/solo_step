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

  // Hardcoded mock values that mimic the previous UI state for target budgets
  static const int _totalBudget = 18000;
  static const int _dailyTarget = 6000;
  static const int _estimatedToDate = 3600;

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
      final ref = _expensesRef(tripId);
      if (ref == null) throw Exception('User not authenticated');
      
      final snapshot = await ref.get(const GetOptions(source: Source.serverAndCache));
      
      int totalSpent = 0;
      for (var doc in snapshot.docs) {
        final expense = domain.Expense.fromMap(doc.data(), doc.id);
        totalSpent += expense.amountInr;
      }

      return BudgetSummary(
        totalBudgetInr: _totalBudget,
        dailyTargetInr: _dailyTarget,
        spentInr: totalSpent,
        estimatedToDateInr: _estimatedToDate,
      );
    } catch (err) {
      debugPrint('Error calculating summary: $err');
      // Fallback
      return const BudgetSummary(
        totalBudgetInr: _totalBudget,
        dailyTargetInr: _dailyTarget,
        spentInr: 0,
        estimatedToDateInr: _estimatedToDate,
      );
    }
  }

  @override
  Future<void> syncPending() async {
    // No-op. Firestore SDK natively handles offline sync in the background automatically.
    // There is no need to manually implement a sync loop!
  }
}
