import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/gemini_adviser_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';
import '../../../mood_detection/data/models/emotion_result.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiAdviserService _geminiService = GeminiAdviserService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! I'm MindHeal Assistant, your AI wellness assistant. I have access to your mood and heart rate history to provide personalized guidance. How are you feeling today?",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MindHeal Assistant'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingBubble();
                }
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Quick Actions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction('Feeling anxious', Icons.psychology),
                  const SizedBox(width: 8),
                  _buildQuickAction('Sleep issues', Icons.bedtime),
                  const SizedBox(width: 8),
                  _buildQuickAction('Stress management', Icons.spa),
                  const SizedBox(width: 8),
                  _buildQuickAction('Mood tracking', Icons.mood),
                ],
              ),
            ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    onPressed: () {
                      _sendMessage();
                    },
                    icon: const Icon(Icons.send),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MindHeal is thinking...',
                    style: TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String text, IconData icon) {
    return InkWell(
      onTap: () {
        _messageController.text = text;
        _sendMessage();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: _messageController.text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    final userInput = _messageController.text.trim();
    _messageController.clear();

    try {
      // Get user's wellness history
      final moodHistory = await _getMoodHistory();
      final bpmHistory = await _getBpmHistory();

      // Create comprehensive prompt for Gemini
      final prompt = _buildCounselorPrompt(userInput, moodHistory, bpmHistory);

      // Get response from Gemini
      final response = await _geminiService.getChatResponse(
        userMessage: userInput,
        wellnessContext: prompt,
      );

      final aiMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
    } catch (e) {
      // Fallback response if Gemini fails
      final aiMessage = ChatMessage(
        text:
            "I apologize, but I'm having trouble connecting right now. However, I'm here to listen. Can you tell me more about how you're feeling today?",
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<List<EmotionResult>> _getMoodHistory() async {
    try {
      // Get the last 10 mood sessions
      final moodStream = _firestoreService.getMoodHistory();
      final moodData = await moodStream.first;
      return moodData.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<HeartRateMeasurement>> _getBpmHistory() async {
    try {
      // Get the last 10 BPM measurements
      final bpmStream = _firestoreService.getBiofeedbackHistory();
      final bpmData = await bpmStream.first;
      return bpmData.take(10).toList();
    } catch (e) {
      return [];
    }
  }

  String _buildCounselorPrompt(String userInput,
      List<EmotionResult> moodHistory, List<HeartRateMeasurement> bpmHistory) {
    final buffer = StringBuffer();

    buffer.writeln(
        "You are a compassionate AI wellness counselor and friend. Respond warmly, empathetically, and provide helpful guidance.");
    buffer.writeln("User Message: \"$userInput\"");
    buffer.writeln();

    // Add mood history context
    if (moodHistory.isNotEmpty) {
      buffer.writeln("RECENT MOOD HISTORY:");
      for (int i = 0; i < moodHistory.length && i < 5; i++) {
        final mood = moodHistory[i];
        final timeAgo = _getTimeAgo(mood.timestamp);
        buffer.writeln(
            "- ${mood.emotion} (${(mood.confidence * 100).toInt()}% confidence) - $timeAgo");
      }
      buffer.writeln();
    }

    // Add BPM history context
    if (bpmHistory.isNotEmpty) {
      buffer.writeln("RECENT HEART RATE DATA:");
      for (int i = 0; i < bpmHistory.length && i < 5; i++) {
        final bpm = bpmHistory[i];
        final timeAgo = _getTimeAgo(bpm.timestamp);
        final method = bpm.method.toString().split('.').last;
        buffer.writeln("- ${bpm.bpm} BPM via $method - $timeAgo");
      }
      buffer.writeln();
    }

    buffer.writeln("Guidelines:");
    buffer.writeln("- Be supportive, understanding, and friendly");
    buffer.writeln("- Reference their mood and health patterns when relevant");
    buffer.writeln("- Provide practical advice and coping strategies");
    buffer.writeln(
        "- Ask follow-up questions to understand their feelings better");
    buffer.writeln("- Suggest relaxation techniques if they seem stressed");
    buffer.writeln("- Keep responses conversational and encouraging");
    buffer.writeln("- Limit response to 2-3 paragraphs maximum");

    return buffer.toString();
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
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
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
