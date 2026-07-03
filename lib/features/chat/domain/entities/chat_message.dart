import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String role; // 'user' or 'model'
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      role: map['role'] as String,
      text: map['text'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
