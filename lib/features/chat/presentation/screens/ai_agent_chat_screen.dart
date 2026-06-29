import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:go_router/go_router.dart';

class AiAgentChatScreen extends StatefulWidget {
  final String destinationName;

  const AiAgentChatScreen({super.key, required this.destinationName});

  @override
  State<AiAgentChatScreen> createState() => _AiAgentChatScreenState();
}

class _AiAgentChatScreenState extends State<AiAgentChatScreen> {
  late final ChatSession _chatSession;
  final List<Map<String, String>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Error: GEMINI_API_KEY is not configured in .env'
        });
      });
      return;
    }

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'You are an expert, highly protective local guide and travel assistant for a solo female traveler currently in ${widget.destinationName}. '
        'Your goal is to provide immediate, actionable, and safe logistical advice. '
        'If she asks for directions, give exact step-by-step transit instructions (e.g., which metro line, which gate, what landmarks to look for). '
        'Always prioritize her safety, suggest avoiding unsafe areas especially at night, and provide practical tips. '
        'Keep responses concise, clear, and easy to read on the go.'
      ),
    );

    _chatSession = model.startChat();
    
    // Add initial greeting
    setState(() {
      _messages.add({
        'role': 'model',
        'text': 'Hi! I am your local fixer for ${widget.destinationName}. Let me know if you need safe directions, food recommendations, or help navigating right now.'
      });
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      final responseText = response.text;
      
      if (responseText != null) {
        setState(() {
          _messages.add({'role': 'model', 'text': responseText});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'model',
          'text': 'Sorry, I encountered an error: $e'
        });
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
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15102A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(157, 78, 221, 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent, color: Color(0xFFC77DFF), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'Local Fixer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18 * textScale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color.fromRGBO(255, 255, 255, 0.05),
            height: 1.0,
          ),
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
                final isUser = message['role'] == 'user';
                return _ChatBubble(
                  text: message['text'] ?? '',
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
                child: CircularProgressIndicator(color: Color(0xFFC77DFF), strokeWidth: 2),
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
      decoration: const BoxDecoration(
        color: Color(0xFF15102A),
        border: Border(
          top: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.1)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ask for safe directions...',
                        hintStyle: TextStyle(color: Colors.white30),
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
                color: Color(0xFF9D4EDD),
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
          color: isUser ? const Color(0xFF9D4EDD) : const Color.fromRGBO(255, 255, 255, 0.08),
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
            color: Colors.white,
            fontSize: 14 * textScale,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
