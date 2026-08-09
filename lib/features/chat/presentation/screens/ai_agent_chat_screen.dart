import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../itinerary/presentation/providers/itinerary_provider.dart';
import '../../domain/entities/chat_message.dart';
import '../providers/chat_provider.dart';

class AiAgentChatScreen extends ConsumerStatefulWidget {
  final String tripId;
  final String destinationName;

  const AiAgentChatScreen({
    super.key,
    required this.tripId,
    required this.destinationName,
  });

  @override
  ConsumerState<AiAgentChatScreen> createState() => _AiAgentChatScreenState();
}

class _AiAgentChatScreenState extends ConsumerState<AiAgentChatScreen> {
  ChatSession? _chatSession;
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      if (!AppConfig.instance.hasGeminiApiKey) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: const Uuid().v4(),
              role: 'model',
              text: 'Gemini API key is not configured. Run the app with `--dart-define=GEMINI_API_KEY=YOUR_KEY` and restart to use chat.',
              timestamp: DateTime.now(),
            ),
          );
        });
        return;
      }

      final apiKey = AppConfig.instance.geminiApiKeyOrThrow;
      setState(() => _isLoading = true);

      // Get active itinerary
      final itineraries = ref.read(itineraryProvider);
      final itinerary = itineraries.value;

      String itineraryContext = 'Here is her current active itinerary:\n';
      if (itinerary == null || itinerary.days.isEmpty) {
        itineraryContext += 'No activities planned yet.\n';
      } else {
        for (var day in itinerary.days) {
          itineraryContext += 'Day ${day.dayNumber}:\n';
          for (var activity in day.activities) {
            itineraryContext += '- ${activity.time}: ${activity.title}\n';
          }
        }
      }

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          'You are an expert, highly protective local guide and travel assistant for a solo female traveler currently in ${widget.destinationName}. '
          'Your goal is to provide immediate, actionable, and safe logistical advice. '
          'If she asks for directions, give exact step-by-step transit instructions (e.g., which metro line, which gate, what landmarks to look for). '
          'Always prioritize her safety, suggest avoiding unsafe areas especially at night, and provide practical tips. '
          'Keep responses concise, clear, and easy to read on the go.\n\n'
          '$itineraryContext',
        ),
      );

      final repo = ref.read(chatRepositoryProvider);
      final pastMessages = await repo
          .getMessagesStream(user.uid, widget.tripId)
          .first;

      final history = pastMessages
          .map((m) => Content(m.role, [TextPart(m.text)]))
          .toList();
      _chatSession = model.startChat(history: history);

      setState(() {
        _messages.clear();
        _messages.addAll(pastMessages);
        _isLoading = false;
      });

      _scrollToBottom();

      if (pastMessages.isEmpty) {
        final welcome = ChatMessage(
          id: const Uuid().v4(),
          role: 'model',
          text:
              'Hi! I am your local fixer for ${widget.destinationName}. Let me know if you need safe directions, food recommendations, or help navigating right now.',
          timestamp: DateTime.now(),
        );
        await repo.addMessage(user.uid, widget.tripId, welcome);
        setState(() {
          _messages.add(welcome);
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: const Uuid().v4(),
            role: 'model',
            text: 'Error initializing chat: $e',
            timestamp: DateTime.now(),
          ),
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_chatSession == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    // Save to Firestore asynchronously
    final repo = ref.read(chatRepositoryProvider);
    repo.addMessage(user.uid, widget.tripId, userMsg);

    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      final responseText = response.text;

      if (responseText != null) {
        final modelMsg = ChatMessage(
          id: const Uuid().v4(),
          role: 'model',
          text: responseText,
          timestamp: DateTime.now(),
        );
        setState(() {
          _messages.add(modelMsg);
        });
        repo.addMessage(user.uid, widget.tripId, modelMsg);
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            id: const Uuid().v4(),
            role: 'model',
            text: 'Sorry, I encountered an error: $e',
            timestamp: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFF2C3E50),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Local Fixer',
              style: TextStyle(
                color: const Color(0xFF1A1A1A),
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == 'user';
                return _ChatBubble(
                  text: message.text,
                  isUser: isUser,
                  textScale: textScale,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF2C3E50),
                  strokeWidth: 2,
                ),
              ),
            ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Color(0xFF1A1A1A)),
                      decoration: const InputDecoration(
                        hintText: 'Ask for safe directions...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final double textScale;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2C3E50) : Colors.white,
          border: isUser ? null : Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFF1A1A1A),
            fontSize: 14 * textScale,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
