import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../../data/models/emotion_result.dart';

class ImageDetectionProvider with ChangeNotifier {
  // Simple stub implementation
  String? _selectedGender;
  String? _selectedAge;
  EmotionResult? _currentResult;
  bool _isFetchingAdvice = false;
  String? _adviceText;
  bool _isSpeaking = false;
  String _selectedLanguage = 'English';

  // Languages configuration
  final List<String> _availableLanguages = ['English', 'Hindi', 'Gujarati'];

  String? get selectedGender => _selectedGender;
  String? get selectedAge => _selectedAge;
  EmotionResult? get currentResult => _currentResult;
  bool get isFetchingAdvice => _isFetchingAdvice;
  String? get adviceText => _adviceText;
  bool get isSpeaking => _isSpeaking;
  String get selectedLanguage => _selectedLanguage;
  List<String> get availableLanguages => _availableLanguages;

  // Additional properties needed for ONNX camera widget
  String? get error => null; // No errors in basic implementation
  bool get isInitialized => true; // Always initialized
  bool get isProcessing =>
      _isFetchingAdvice; // Use advice fetching as processing indicator
  bool get isRealTimeMode => false; // Not supported in basic provider
  CameraController? get cameraController => null; // Not used in basic provider

  void setGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  void setAge(String age) {
    _selectedAge = age;
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  Future<void> processImage(String imagePath) async {
    // Stub implementation - creates dummy result
    await Future.delayed(Duration(milliseconds: 500));
    _currentResult = EmotionResult(
      emotion: 'neutral',
      confidence: 0.8,
      allEmotions: {
        'neutral': 0.8,
        'happy': 0.1,
        'sad': 0.05,
        'angry': 0.03,
        'surprised': 0.02,
      },
      timestamp: DateTime.now(),
      processingTimeMs: 500,
    );
    notifyListeners();
  }

  Future<void> analyzeImage(String imagePath) async {
    await processImage(imagePath);
  }

  Future<void> fetchAdviceForMood(String mood) async {
    _isFetchingAdvice = true;
    _adviceText = null;
    notifyListeners();

    await Future.delayed(Duration(seconds: 1));

    _adviceText =
        "This is a demo advice for $mood mood in $_selectedLanguage language.";
    _isFetchingAdvice = false;
    notifyListeners();
  }

  void reset() {
    _currentResult = null;
    _adviceText = null;
    _isFetchingAdvice = false;
    _isSpeaking = false;
    notifyListeners();
  }

  void resetAdviceStateOnly() {
    _adviceText = null;
    _isFetchingAdvice = false;
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> speakAdvice() async {
    if (_adviceText != null && !_isSpeaking) {
      _isSpeaking = true;
      notifyListeners();

      // Simulate TTS playback
      await Future.delayed(Duration(seconds: 3));

      _isSpeaking = false;
      notifyListeners();
    }
  }

  void stopSpeaking() {
    if (_isSpeaking) {
      _isSpeaking = false;
      notifyListeners();
    }
  }

  // Additional methods needed for ONNX camera widget compatibility
  Future<void> initialize() async {
    // Already initialized in basic provider
  }

  Future<void> initializeCamera() async {
    // Camera not used in basic provider
  }

  Future<void> startRealTimeDetection() async {
    // Real-time detection not supported in basic provider
  }

  void stopRealTimeDetection() {
    // Real-time detection not supported in basic provider
  }

  Future<void> switchCamera() async {
    // Camera switching not supported in basic provider
  }

  Future<void> fetchAdvice() async {
    if (_currentResult != null) {
      await fetchAdviceForMood(_currentResult!.emotion);
    }
  }
}
