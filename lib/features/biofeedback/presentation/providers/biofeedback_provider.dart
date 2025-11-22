import 'package:flutter/foundation.dart';
import '../../data/models/biofeedback_data.dart';

class BiofeedbackProvider extends ChangeNotifier {
  BiofeedbackData? _currentData;

  // Getters
  BiofeedbackData? get currentData => _currentData;

  // Update data from heart rate measurement
  void updateHeartRate(int heartRate) {
    _currentData = BiofeedbackData(
      timestamp: DateTime.now(),
      heartRate: heartRate,
      stressLevel: _calculateStressLevel(heartRate),
      hrvScore: _calculateHRV(heartRate),
      breathingRate: _calculateBreathingRate(heartRate),
    );
    notifyListeners();
  }

  // Update complete data
  void updateData(BiofeedbackData data) {
    _currentData = data;
    notifyListeners();
  }

  // Clear data
  void clearData() {
    _currentData = null;
    notifyListeners();
  }

  // Helper methods to calculate derived metrics
  double _calculateStressLevel(int heartRate) {
    // Simple stress calculation based on heart rate
    if (heartRate < 60) return 0.2;
    if (heartRate > 100) return 0.8;
    return 0.3 + ((heartRate - 60) / 100);
  }

  int _calculateHRV(int heartRate) {
    // Simple HRV estimation (inverse relationship with heart rate)
    return (100 - (heartRate - 50)).clamp(20, 80);
  }

  int _calculateBreathingRate(int heartRate) {
    // Breathing rate correlation with heart rate
    return (heartRate / 4).round().clamp(12, 20);
  }
}
