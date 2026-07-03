import '../entities/chat_message.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> getMessagesStream(String userId, String tripId);
  Future<void> addMessage(String userId, String tripId, ChatMessage message);
}
