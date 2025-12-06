import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/gemini_adviser_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';
import '../../../../shared/models/chat_session.dart';
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
  bool _isSavingEnabled = true; // Toggle for saving chats

  // Chat session management
  String _currentChatId = '';
  List<ChatSession> _chatSessions = [];

  // Language selection
  String _selectedLanguage = 'English';

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          "Hello! I'm your Best friend 🌙, your AI wellness assistant. I have access to your mood and heart rate history to provide personalized guidance. How are you feeling today? 💝",
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistoryFromFirestore();
    _createNewSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BFF 💙'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showChatHistory,
            tooltip: 'Chat History',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More Options',
            onSelected: (String language) {
              setState(() {
                _selectedLanguage = language;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Language changed to $_selectedLanguage 🌍'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'English',
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: _selectedLanguage == 'English'
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'English',
                      style: TextStyle(
                        fontWeight: _selectedLanguage == 'English'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedLanguage == 'English'
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    if (_selectedLanguage == 'English') ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'हिंदी',
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: _selectedLanguage == 'हिंदी'
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'हिंदी (Hindi)',
                      style: TextStyle(
                        fontWeight: _selectedLanguage == 'हिंदी'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedLanguage == 'हिंदी'
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    if (_selectedLanguage == 'हिंदी') ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'ગુજરાતી',
                child: Row(
                  children: [
                    Icon(
                      Icons.language,
                      color: _selectedLanguage == 'ગુજરાતી'
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ગુજરાતી (Gujarati)',
                      style: TextStyle(
                        fontWeight: _selectedLanguage == 'ગુજરાતી'
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedLanguage == 'ગુજરાતી'
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    if (_selectedLanguage == 'ગુજરાતી') ...[
                      const Spacer(),
                      Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                    ],
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                enabled: false,
                child: StatefulBuilder(
                  builder: (context, setMenuState) {
                    return Row(
                      children: [
                        Icon(
                          _isSavingEnabled ? Icons.save : Icons.save_outlined,
                          color: _isSavingEnabled
                              ? Theme.of(context).primaryColor
                              : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Save Chats',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                        Switch(
                          value: _isSavingEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isSavingEnabled = value;
                            });
                            setMenuState(() {}); // Update menu item
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _isSavingEnabled
                                      ? 'Chat saving enabled 💾'
                                      : 'Chat saving disabled 🚫',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
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
                top: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                  fontSize: 16, // Increased font size for better readability
                  height: 1.4, // Better line spacing
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
              child: const Icon(Icons.person, color: Colors.grey, size: 20),
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
            Text(text, style: TextStyle(color: Colors.grey[600])),
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

    // Save user message to Firestore
    await _saveMessageToFirestore(userMessage);

    final userInput = _messageController.text.trim();
    _messageController.clear();

    try {
      print('📱 User sent: "$userInput"');

      // Check if service is configured
      if (!_geminiService.isConfigured) {
        print(
          '❌ Gemini service not configured! API key: ${_geminiService.apiKeyPreview}',
        );
      } else {
        print(
          '✅ Gemini service configured. API key: ${_geminiService.apiKeyPreview}',
        );
      }

      // Get user's wellness history
      print('📊 Fetching user wellness history...');
      final moodHistory = await _getMoodHistory();
      final bpmHistory = await _getBpmHistory();
      print(
        '📊 Mood history: ${moodHistory.length} entries, BPM history: ${bpmHistory.length} entries',
      );

      // Create comprehensive prompt for Gemini
      final prompt = _buildCounselorPrompt(userInput, moodHistory, bpmHistory);
      print('📝 Generated wellness context (${prompt.length} chars)');

      // Get response from Gemini
      print('🤖 Calling Gemini API...');
      final response = await _geminiService.getChatResponse(
        userMessage: userInput,
        wellnessContext: prompt,
        language: _selectedLanguage,
      );
      print(
        '✅ Gemini response received (${response.length} chars): ${response.substring(0, response.length > 100 ? 100 : response.length)}...',
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

      // Save AI response to Firestore
      await _saveMessageToFirestore(aiMessage);
    } catch (e) {
      print('❌ Error in _sendMessage: $e');

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

      // Save fallback message to Firestore
      await _saveMessageToFirestore(aiMessage);
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

  String _buildCounselorPrompt(
    String userInput,
    List<EmotionResult> moodHistory,
    List<HeartRateMeasurement> bpmHistory,
  ) {
    final buffer = StringBuffer();

    buffer.writeln(
      "You are a compassionate AI wellness counselor and friend. Respond warmly, empathetically, and provide helpful guidance.",
    );
    buffer.writeln("User Message: \"$userInput\"");
    buffer.writeln();

    // Add mood history context
    if (moodHistory.isNotEmpty) {
      buffer.writeln("RECENT MOOD HISTORY:");
      for (int i = 0; i < moodHistory.length && i < 5; i++) {
        final mood = moodHistory[i];
        final timeAgo = _getTimeAgo(mood.timestamp);
        buffer.writeln(
          "- ${mood.emotion} (${(mood.confidence * 100).toInt()}% confidence) - $timeAgo",
        );
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
      "- Ask follow-up questions to understand their feelings better",
    );
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

  // New chat functionality methods
  Future<void> _startNewChat() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If user is not logged in, just clear the local messages
      String welcomeMessage = _getWelcomeMessage();
      setState(() {
        _messages.clear();
        _messages.add(
          ChatMessage(
            text: welcomeMessage,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } else {
      // Create a new session in Firestore for logged-in users
      await _createNewSession();
    }

    // Show snackbar to confirm new chat started
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_getNewChatMessage()),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getWelcomeMessage() {
    switch (_selectedLanguage) {
      case 'Hindi':
        return "नमस्ते! 🌙 मैं MindHeal हूं, आपकी देखभाल करने वाली दोस्त और wellness साथी। आज आप कैसा महसूस कर रहे हैं? 💝";
      case 'Gujarati':
        return "નમસ્તે! 🌙 હું MindHeal છું, તમારી કેરિંગ મિત્ર અને wellness સાથી. આજે તમે કેવું લાગે છે? 💝";
      default:
        return "Hi there! 🌙 I'm MindHeal, your caring friend and wellness companion. How are you feeling today? 💝";
    }
  }

  String _getNewChatMessage() {
    switch (_selectedLanguage) {
      case 'Hindi':
        return "नई चैट शुरू! 🌟";
      case 'Gujarati':
        return "નવી ચેટ શરૂ! 🌟";
      default:
        return "New chat started! 🌟";
    }
  }

  // Firestore chat persistence methods
  Future<void> _loadChatHistoryFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, skipping chat history load');
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .orderBy('lastUpdated', descending: true)
          .get();

      setState(() {
        _chatSessions = querySnapshot.docs
            .map((doc) => ChatSession.fromJson({...doc.data(), 'id': doc.id}))
            .toList();
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _createNewSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not logged in, cannot create Firestore session');
      return;
    }

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    final welcomeMessage = _getWelcomeMessage();

    final newSession = ChatSession(
      id: sessionId,
      title: 'Chat ${DateTime.now().day}/${DateTime.now().month}',
      lastUpdated: DateTime.now(),
      messageCount: 1, // Welcome message
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .set(newSession.toJson());

      // Save welcome message
      final welcomeChatMessage = ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      await _saveMessageToFirestore(welcomeChatMessage);

      setState(() {
        _currentChatId = sessionId;
        _chatSessions.insert(0, newSession);
        _messages.clear();
        _messages.add(welcomeChatMessage);
      });

      _scrollToBottom();
    } catch (e) {
      print('Error creating new session: $e');
      // Fallback to local-only session
      final welcomeChatMessage = ChatMessage(
        text: welcomeMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _currentChatId = '';
        _messages.clear();
        _messages.add(welcomeChatMessage);
      });

      _scrollToBottom();

      // Show user that chat history won't be saved
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chat history unavailable - messages won\'t be saved',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveMessageToFirestore(ChatMessage message) async {
    // Check if saving is enabled
    if (!_isSavingEnabled) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentChatId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(_currentChatId)
          .collection('messages')
          .add({
        'text': message.text,
        'isUser': message.isUser,
        'timestamp': message.timestamp.toIso8601String(),
      });

      // Update session message count and last updated
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(_currentChatId)
          .update({
        'messageCount': FieldValue.increment(1),
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving message: $e');
      // Silently fail for now - message is already in local UI
    }
  }

  Future<void> _loadChatSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .collection('messages')
          .orderBy('timestamp')
          .get();

      final messages = messagesSnapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          text: data['text'],
          isUser: data['isUser'],
          timestamp: DateTime.parse(data['timestamp']),
        );
      }).toList();

      setState(() {
        _currentChatId = sessionId;
        _messages.clear();
        _messages.addAll(messages);
      });

      _scrollToBottom();
    } catch (e) {
      print('Error loading chat session: $e');
    }
  }

  String _formatChatDate(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        // Today
        return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        // This week
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${weekdays[dateTime.weekday - 1]} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        // More than a week
        final day = dateTime.day.clamp(1, 31);
        final month = dateTime.month.clamp(1, 12);
        return '$day/$month/${dateTime.year}';
      }
    } catch (e) {
      print('Error formatting date: $e');
      return 'Invalid date';
    }
  }

  void _showChatHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Show message that user needs to be logged in
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to access chat history'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Reload chat history before showing
    await _loadChatHistoryFromFirestore();

    // Always show the dialog, even if empty
    // The dialog itself will handle the empty state with a nice UI

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _chatSessions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Chat History Yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start your first conversation with BFF! 💙',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _startNewChat();
                              },
                              icon: const Icon(Icons.add_comment),
                              label: const Text('Start New Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatSessions.length,
                        itemBuilder: (context, index) {
                          final session = _chatSessions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  session.lastUpdated.day
                                      .clamp(1, 31)
                                      .toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                session.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${session.messageCount} messages',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  Text(
                                    _formatChatDate(session.lastUpdated),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _deleteChatSession(session.id),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _loadChatSession(session.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteChatSession(String sessionId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat?'),
        content: const Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete the chat session document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_sessions')
          .doc(sessionId)
          .delete();

      // Reload chat history
      await _loadChatHistoryFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Chat deleted successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // If deleted current session, start a new one
        if (sessionId == _currentChatId) {
          _startNewChat();
        }
      }
    } catch (e) {
      print('Error deleting chat session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
