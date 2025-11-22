import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../data/models/emotion_result.dart';
import '../../../../core/services/gemini_adviser_service.dart';

class AdviceDialog extends StatefulWidget {
  final EmotionResult emotionResult;
  final String? userSpeech; // Added parameter

  const AdviceDialog({
    super.key, 
    required this.emotionResult,
    this.userSpeech, // Added to constructor
  });

  @override
  State<AdviceDialog> createState() => _AdviceDialogState();
}

class _AdviceDialogState extends State<AdviceDialog>
    with TickerProviderStateMixin {
  final GeminiAdviserService _adviserService = GeminiAdviserService();
  final FlutterTts _flutterTts = FlutterTts();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String? _advice;
  bool _isLoading = false;
  String? _error;
  String _selectedLanguage = 'English';
  bool _isSpeaking = false;
  bool _isPaused = false;

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'hi', 'name': 'हिंदी', 'flag': '🇮🇳'},
    {'code': 'gu', 'name': 'ગુજરાતી', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeTts();

    // Debug the service configuration immediately
    print(
        '🔍 AdviceDialog initState: Service configured: ${_adviserService.isConfigured}');
    print(
        '🔍 AdviceDialog initState: API Key preview: ${_adviserService.apiKeyPreview}');

    _getAdvice();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  Future<void> _initializeTts() async {
    try {
      // Wait for TTS engine to be available
      await Future.delayed(const Duration(milliseconds: 1000));

      // Check if TTS is available
      var engines = await _flutterTts.getEngines;
      if (engines.isEmpty) {
        print('No TTS engines available');
        return;
      }

      // Initialize TTS settings
      await _flutterTts.setVolume(0.8);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);

      // Set default language and check availability
      var isAvailable = await _flutterTts.isLanguageAvailable('en-US');
      if (isAvailable == true) {
        await _flutterTts.setLanguage('en-US');
      }

      _flutterTts.setStartHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = true;
            _isPaused = false;
          });
        }
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
        }
      });

      _flutterTts.setPauseHandler(() {
        if (mounted) {
          setState(() {
            _isPaused = true;
          });
        }
      });

      _flutterTts.setContinueHandler(() {
        if (mounted) {
          setState(() {
            _isPaused = false;
          });
        }
      });

      _flutterTts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _isSpeaking = false;
            _isPaused = false;
          });
        }
      });
    } catch (e) {
      print('TTS Initialization Error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _flutterTts.stop();
    } catch (e) {
      print('TTS Dispose Error: $e');
    }
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getAdvice() async {
    print('🎯 AdviceDialog: Starting _getAdvice()');
    print('🎯 Emotion: ${widget.emotionResult.emotion}');
    print('🎯 Confidence: ${widget.emotionResult.confidence}');
    print('🎯 Language: $_selectedLanguage');

    // Check service configuration in dialog
    print(
        '🎯 AdviceDialog: Service configured: ${_adviserService.isConfigured}');
    print('🎯 AdviceDialog: API Key preview: ${_adviserService.apiKeyPreview}');

    // Force test the API connection directly
    try {
      print('🧪 Testing API connection from dialog...');
      final testResult = await _adviserService.testApiConnection();
      print('🧪 API connection test result: $testResult');
    } catch (e) {
      print('🧪 API connection test failed: $e');
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🎯 AdviceDialog: Calling _adviserService.getEmotionalAdvice()');
      
      // Use userSpeech if provided
      String advice;
      if (widget.userSpeech != null && widget.userSpeech!.isNotEmpty && !widget.userSpeech!.startsWith("(")) {
         advice = await _adviserService.getConversationalAdvice(
           userSpeech: widget.userSpeech!,
           detectedEmotion: widget.emotionResult.emotion,
           language: _selectedLanguage,
         );
      } else {
         advice = await _adviserService.getEmotionalAdvice(
          detectedEmotion: widget.emotionResult.emotion,
          confidence: widget.emotionResult.confidence,
          language: _selectedLanguage,
        );
      }

      print('🎯 AdviceDialog: Received advice length: ${advice.length}');
      print(
          '🎯 AdviceDialog: First 100 chars: ${advice.substring(0, advice.length > 100 ? 100 : advice.length)}...');

      setState(() {
        _advice = advice;
        _isLoading = false;
      });
    } catch (e) {
      print('🎯 AdviceDialog: ERROR - $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeLanguage(String language) {
    if (language != _selectedLanguage) {
      setState(() {
        _selectedLanguage = language;
      });
      _getAdvice();
    }
  }

  Future<void> _speakAdvice() async {
    if (_advice == null || _advice!.isEmpty) return;

    try {
      // Check if TTS engine is available before trying to use it
      var engines = await _flutterTts.getEngines;
      if (engines.isEmpty) {
        _showTtsNotAvailableMessage();
        return;
      }

      await _flutterTts.stop();

      // Set language for TTS and check if it's available
      String languageCode = _getLanguageCode(_selectedLanguage);
      var isAvailable = await _flutterTts.isLanguageAvailable(languageCode);

      if (isAvailable == true) {
        await _flutterTts.setLanguage(languageCode);
      } else {
        // Fallback to English if selected language is not available
        await _flutterTts.setLanguage('en-US');
      }

      // Wait a bit for TTS to be ready
      await Future.delayed(const Duration(milliseconds: 200));

      var result = await _flutterTts.speak(_advice!);
      if (result == 0) {
        // Speech started successfully
        print('TTS started successfully');
      }
    } catch (e) {
      print('TTS Speak Error: $e');
      // Only show error dialog if we haven't already shown one recently
      if (mounted && !_isSpeaking) {
        _showTtsNotAvailableMessage();
      }
    }
  }

  void _showTtsNotAvailableMessage() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('TTS Not Available'),
              ],
            ),
            content: const Text(
              'Text-to-speech is not available. Please install Google TTS or enable speech services on your device.',
              style: TextStyle(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.orange.shade600),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _pauseResumeSpeech() async {
    try {
      var engines = await _flutterTts.getEngines;
      if (engines.isEmpty) {
        _showTtsNotAvailableMessage();
        return;
      }

      if (_isSpeaking && !_isPaused) {
        await _flutterTts.pause();
      } else if (_isPaused) {
        await _flutterTts.speak(_advice!);
      }
    } catch (e) {
      print('TTS Pause/Resume Error: $e');
      _showTtsNotAvailableMessage();
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('TTS Stop Error: $e');
    }
  }

  String _getLanguageCode(String language) {
    switch (language) {
      case 'हिंदी':
        return 'hi-IN';
      case 'ગુજરાતી':
        return 'gu-IN';
      case 'English':
      default:
        return 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                Flexible(child: _buildContent()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.purple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MindHeal Adviser',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Personalized guidance for ${widget.emotionResult.emotion.toLowerCase()} mood',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final isSelected = _selectedLanguage == lang['name'];
            return GestureDetector(
              onTap: () => _changeLanguage(lang['name']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        lang['name']!,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.purple.shade600
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildEmotionCard(),
            const SizedBox(height: 20),
            _buildAdviceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getEmotionColor(widget.emotionResult.emotion).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getEmotionColor(
            widget.emotionResult.emotion,
          ).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getEmotionColor(
                widget.emotionResult.emotion,
              ).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              _getEmotionEmoji(widget.emotionResult.emotion),
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedEmotion(widget.emotionResult.emotion),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getEmotionColor(widget.emotionResult.emotion),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(widget.emotionResult.confidence * 100).toInt()}% ${_getLocalizedText('confidence')}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceSection() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_advice != null) {
      return _buildAdviceContent();
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _getLocalizedText('gettingAdvice'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _getLocalizedText('pleaseWait'),
            style: TextStyle(fontSize: 14, color: Colors.blue.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
          const SizedBox(height: 12),
          Text(
            _getLocalizedText('adviceError'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getAdvice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text(_getLocalizedText('tryAgain')),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.green.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _getLocalizedText('personalizedAdvice'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _advice!,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildSpeechControls(),
        ],
      ),
    );
  }

  Widget _buildSpeechControls() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.volume_up, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            _getLocalizedText('readAloud'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpeechButton(
                icon: _isSpeaking
                    ? (_isPaused ? Icons.play_arrow : Icons.pause)
                    : Icons.play_arrow,
                onPressed: _isSpeaking ? _pauseResumeSpeech : _speakAdvice,
                color: Colors.blue,
                tooltip: _isSpeaking
                    ? (_isPaused
                        ? _getLocalizedText('resume')
                        : _getLocalizedText('pause'))
                    : _getLocalizedText('play'),
              ),
              const SizedBox(width: 8),
              _buildSpeechButton(
                icon: Icons.stop,
                onPressed: _isSpeaking ? _stopSpeech : null,
                color: Colors.red,
                tooltip: _getLocalizedText('stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeechButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: onPressed != null
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: onPressed != null ? color : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _getAdvice,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.purple.shade600,
                side: BorderSide(color: Colors.purple.shade600),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh, size: 18),
                  const SizedBox(width: 8),
                  Text(_getLocalizedText('newAdvice')),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_getLocalizedText('close')),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedText(String key) {
    final texts = {
      'English': {
        'confidence': 'confidence',
        'gettingAdvice': 'Getting personalized advice...',
        'pleaseWait':
            'Please wait while our AI counselor prepares guidance for you',
        'adviceError': 'Unable to get advice at the moment',
        'tryAgain': 'Try Again',
        'personalizedAdvice': 'Personalized Advice',
        'newAdvice': 'New Advice',
        'close': 'Close',
        'readAloud': 'Read Aloud',
        'play': 'Play',
        'pause': 'Pause',
        'resume': 'Resume',
        'stop': 'Stop',
      },
      'हिंदी': {
        'confidence': 'विश्वास',
        'gettingAdvice': 'व्यक्तिगत सलाह प्राप्त की जा रही है...',
        'pleaseWait':
            'कृपया प्रतीक्षा करें जबकि हमारा AI सलाहकार आपके लिए मार्गदर्शन तैयार करता है',
        'adviceError': 'फिलहाल सलाह नहीं मिल पा रही है',
        'tryAgain': 'फिर कोशिश करें',
        'personalizedAdvice': 'व्यक्तिगत सलाह',
        'newAdvice': 'नई सलाह',
        'close': 'बंद करें',
        'readAloud': 'जोर से पढ़ें',
        'play': 'चलाएं',
        'pause': 'रोकें',
        'resume': 'जारी रखें',
        'stop': 'बंद करें',
      },
      'ગુજરાતી': {
        'confidence': 'વિશ્વાસ',
        'gettingAdvice': 'વ્યક્તિગત સલાહ મેળવી રહ્યા છીએ...',
        'pleaseWait':
            'કૃપા કરીને રાહ જુઓ જ્યારે અમારો AI સલાહકાર તમારા માટે માર્ગદર્શન તૈયાર કરે છે',
        'adviceError': 'હાલમાં સલાહ મેળવવામાં અસમર્થ',
        'tryAgain': 'ફરી પ્રયાસ કરો',
        'personalizedAdvice': 'વ્યક્તિગત સલાહ',
        'newAdvice': 'નવી સલાહ',
        'close': 'બંધ કરો',
        'readAloud': 'મોટેથી વાંચો',
        'play': 'ચલાવો',
        'pause': 'થોભાવો',
        'resume': 'ચાલુ રાખો',
        'stop': 'બંધ કરો',
      },
    };

    return texts[_selectedLanguage]?[key] ?? texts['English']![key]!;
  }

  String _getLocalizedEmotion(String emotion) {
    final emotions = {
      'English': {
        'happy': 'Happy',
        'sad': 'Sad',
        'angry': 'Angry',
        'fear': 'Fearful',
        'surprise': 'Surprised',
        'disgust': 'Disgusted',
        'neutral': 'Neutral',
      },
      'हिंदी': {
        'happy': 'खुश',
        'sad': 'उदास',
        'angry': 'गुस्सैल',
        'fear': 'डरा हुआ',
        'surprise': 'आश्चर्यचकित',
        'disgust': 'घृणित',
        'neutral': 'तटस्थ',
      },
      'ગુજરાતી': {
        'happy': 'ખુશ',
        'sad': 'દુઃખી',
        'angry': 'ગુસ્સે',
        'fear': 'ડરેલો',
        'surprise': 'આશ્ચર્યચકિત',
        'disgust': 'અણગમતું',
        'neutral': 'તટસ્થ',
      },
    };

    return emotions[_selectedLanguage]?[emotion.toLowerCase()] ??
        emotions['English']![emotion.toLowerCase()] ??
        emotion;
  }

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'happiness':
        return '😊';
      case 'sad':
      case 'sadness':
        return '😢';
      case 'angry':
      case 'anger':
        return '😠';
      case 'fear':
        return '😨';
      case 'surprise':
        return '😮';
      case 'disgust':
        return '🤢';
      case 'neutral':
        return '😐';
      default:
        return '😐';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'happiness':
        return Colors.green;
      case 'sad':
      case 'sadness':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
        return Colors.orange;
      case 'surprise':
        return Colors.purple;
      case 'disgust':
        return Colors.brown;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}