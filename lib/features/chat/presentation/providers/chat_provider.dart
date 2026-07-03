import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/firestore_chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepositoryImpl();
});

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, tripId) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream.empty();
  }

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getMessagesStream(user.uid, tripId);
});
