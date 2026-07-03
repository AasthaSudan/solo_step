import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class FirestoreChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference _getMessagesCollection(String userId, String tripId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('trips')
        .doc(tripId)
        .collection('chat_messages');
  }

  @override
  Stream<List<ChatMessage>> getMessagesStream(String userId, String tripId) {
    return _getMessagesCollection(userId, tripId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ChatMessage.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  @override
  Future<void> addMessage(String userId, String tripId, ChatMessage message) async {
    await _getMessagesCollection(userId, tripId)
        .doc(message.id)
        .set(message.toMap());
  }
}
