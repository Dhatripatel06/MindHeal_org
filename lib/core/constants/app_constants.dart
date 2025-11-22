class AppConstants {
  // App Info
  static const String appName = 'Mental Wellness';
  static const String appVersion = '1.0.0';
  
  // Emotion Labels
  static const List<String> emotionLabels = [
    'neutral',
    'happy', 
    'sad',
    'surprise',
    'fear',
    'disgust',
    'anger',
  ];
  
  // Model Configuration
  static const String tfliteModelPath = 'assets/models/emotion_detection.tflite';
  static const int imageInputSize = 224;
  static const int modelOutputSize = 7;
  
  // Audio Configuration
  static const int sampleRate = 44100;
  static const int audioBufferSize = 4096;
  static const Duration maxRecordingDuration = Duration(minutes: 5);
  static const Duration minRecordingDuration = Duration(seconds: 2);
  
  // UI Configuration
  static const double defaultBorderRadius = 15.0;
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 600);
  static const Duration longAnimation = Duration(milliseconds: 1000);
  
  // Storage Keys
  static const String prefKeyDemoMode = 'demo_mode';
  static const String prefKeyAutoSave = 'auto_save';
  static const String prefKeyNotifications = 'notifications';
  static const String prefKeyDarkMode = 'dark_mode';
  
  // Database Configuration
  static const String dbName = 'mood_detection.db';
  static const int dbVersion = 1;
  
  // Confidence Thresholds
  static const double minConfidenceThreshold = 0.5;
  static const double highConfidenceThreshold = 0.8;
  
  // Colors
  static const Map<String, int> emotionColors = {
    'happy': 0xFF4CAF50,      // Green
    'sad': 0xFF2196F3,        // Blue
    'angry': 0xFFF44336,      // Red
    'fear': 0xFFFF9800,       // Orange
    'surprise': 0xFF9C27B0,   // Purple
    'disgust': 0xFF795548,    // Brown
    'neutral': 0xFF757575,    // Grey
  };
  
  // Analysis Settings
  static const double imageWeight = 0.6;
  static const double audioWeight = 0.4;
  static const Duration analysisInterval = Duration(seconds: 2);
  
  // Export Formats
  static const List<String> exportFormats = ['PDF', 'CSV', 'JSON'];
  
  // Recommendations
  static const Map<String, List<String>> emotionRecommendations = {
    'happy': [
      'Continue engaging in activities that bring you joy',
      'Share your positive energy with others',
      'Consider journaling about what made you happy today',
    ],
    'sad': [
      'Practice self-compassion and allow yourself to feel',
      'Consider reaching out to a friend or loved one',
      'Engage in gentle activities like walking or listening to music',
    ],
    'angry': [
      'Take deep breaths and practice calming techniques',
      'Consider physical exercise to release tension',
      'Reflect on the source of anger when you feel ready',
    ],
    'fear': [
      'Practice grounding techniques to feel more centered',
      'Break down your concerns into manageable steps',
      'Consider seeking support if fear persists',
    ],
    'surprise': [
      'Take time to process unexpected events',
      'Consider what you can learn from this experience',
      'Embrace the unexpected as part of life\'s journey',
    ],
    'disgust': [
      'Identify what specifically triggers this feeling',
      'Consider if boundaries need to be set',
      'Practice self-care and remove yourself from triggers if possible',
    ],
    'neutral': [
      'Take time for self-reflection',
      'Engage in activities that support your well-being',
      'Consider tracking your mood over time',
    ],
  };
}
