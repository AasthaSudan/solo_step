import 'package:flutter/material.dart';

enum SpendCategory {
  food,
  stay,
  activity,
  transport,
  other;

  String get label {
    switch (this) {
      case SpendCategory.food:
        return 'Food';
      case SpendCategory.stay:
        return 'Stay';
      case SpendCategory.activity:
        return 'Activity';
      case SpendCategory.transport:
        return 'Transport';
      case SpendCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case SpendCategory.food:
        return Icons.restaurant_outlined;
      case SpendCategory.stay:
        return Icons.hotel_outlined;
      case SpendCategory.activity:
        return Icons.hiking_outlined;
      case SpendCategory.transport:
        return Icons.directions_car_outlined;
      case SpendCategory.other:
        return Icons.receipt_outlined;
    }
  }

  Color get color {
    switch (this) {
      case SpendCategory.food:
        return const Color(0xFFFBBC05);
      case SpendCategory.stay:
        return const Color(0xFFC77DFF);
      case SpendCategory.activity:
        return const Color(0xFF34A853);
      case SpendCategory.transport:
        return const Color(0xFF4285F4);
      case SpendCategory.other:
        return const Color(0xFF8AB4F8);
    }
  }
}

class Expense {
  final String id;
  final String tripId;
  final int day;
  final SpendCategory category;
  final String label; // Optional, added to match mock data ("Dinner at spice garden")
  final int amountInr;
  final DateTime spentAt;
  final bool synced;

  const Expense({
    required this.id,
    required this.tripId,
    required this.day,
    required this.category,
    required this.label,
    required this.amountInr,
    required this.spentAt,
    this.synced = false,
  });

  Expense copyWith({
    String? id,
    String? tripId,
    int? day,
    SpendCategory? category,
    String? label,
    int? amountInr,
    DateTime? spentAt,
    bool? synced,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      day: day ?? this.day,
      category: category ?? this.category,
      label: label ?? this.label,
      amountInr: amountInr ?? this.amountInr,
      spentAt: spentAt ?? this.spentAt,
      synced: synced ?? this.synced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripId': tripId,
      'day': day,
      'category': category.name,
      'label': label,
      'amountInr': amountInr,
      'spentAt': spentAt.toIso8601String(),
      'synced': synced,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, String id) {
    return Expense(
      id: id,
      tripId: map['tripId'] as String? ?? '',
      day: map['day'] as int? ?? 1,
      category: SpendCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => SpendCategory.other,
      ),
      label: map['label'] as String? ?? '',
      amountInr: map['amountInr'] as int? ?? 0,
      spentAt: map['spentAt'] != null 
          ? DateTime.parse(map['spentAt'] as String) 
          : DateTime.now(),
      synced: map['synced'] as bool? ?? true,
    );
  }
}
