class PackingItem {
  final String id;
  final String name;
  final String category;
  final String reason;
  final bool isPacked;

  const PackingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.reason,
    this.isPacked = false,
  });

  PackingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? reason,
    bool? isPacked,
  }) {
    return PackingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      reason: reason ?? this.reason,
      isPacked: isPacked ?? this.isPacked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'reason': reason,
      'isPacked': isPacked,
    };
  }

  factory PackingItem.fromMap(Map<String, dynamic> map) {
    return PackingItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      reason: map['reason'] as String? ?? '',
      isPacked: map['isPacked'] as bool? ?? false,
    );
  }
}
