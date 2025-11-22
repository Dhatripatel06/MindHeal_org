import 'package:flutter/foundation.dart';

class AppConfig {
  static const bool isDebugMode = kDebugMode;
  static const bool enableDemoMode = true;
  static const bool enableLogging = kDebugMode;
  
  // Feature Flags
  static const bool enableImageDetection = true;
  static const bool enableAudioDetection = true;
  static const bool enableCombinedDetection = true;
  static const bool enableCloudSync = false; // Keep local for now
  static const bool enableExportFeatures = true;
  
  // Performance Settings
  static const int maxHistoryItems = 1000;
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(hours: 24);
  
  // Model Settings
  static const bool useQuantizedModel = true;
  static const int numThreads = 4;
  static const bool useGPUDelegate = false; // Enable if GPU delegate available
  
  // Audio Settings
  static const bool enableNoiseReduction = true;
  static const bool enableVoiceActivityDetection = true;
  static const double voiceActivityThreshold = 0.1;
  
  // UI Settings
  static const bool enableAnimations = true;
  static const bool enableHapticFeedback = true;
  static const bool enableSoundEffects = false;
  
  // Privacy Settings
  static const bool storeDataLocally = true;
  static const bool encryptLocalData = true;
  static const bool anonymizeExports = true;
  
  // Development Settings
  static const bool showDebugInfo = kDebugMode;
  static const bool enablePerformanceMonitoring = kDebugMode;
  static const bool mockMLInference = kDebugMode;
  
  // Validation
  static bool get isValidConfiguration {
    if (!enableImageDetection && !enableAudioDetection && !enableCombinedDetection) {
      return false; // At least one detection method must be enabled
    }
    return true;
  }
  
  // Environment-specific configurations
  static Map<String, dynamic> get environmentConfig {
    if (kDebugMode) {
      return {
        'apiTimeout': 30000,
        'enableDetailedLogging': true,
        'showPerformanceOverlay': false,
        'useLocalAssets': true,
      };
    } else {
      return {
        'apiTimeout': 15000,
        'enableDetailedLogging': false,
        'showPerformanceOverlay': false,
        'useLocalAssets': true,
      };
    }
  }
}
