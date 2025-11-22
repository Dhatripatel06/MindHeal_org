import 'dart:math' as math;

class SignalProcessingService {
  static const double _samplingRate = 30.0; // 30 FPS

  final List<double> _rawData = [];
  final List<double> _filteredData = [];
  final List<double> _movingAverage = [];

  // Butterworth filter coefficients for bandpass filter (0.5-4 Hz)
  static const List<double> _bCoeff = [0.0067, 0, -0.0134, 0, 0.0067];
  static const List<double> _aCoeff = [1.0, -3.1803, 3.8612, -2.1126, 0.4383];

  final List<double> _xHistory = [0, 0, 0, 0, 0];
  final List<double> _yHistory = [0, 0, 0, 0, 0];

  /// Add new data point and return filtered value
  double addDataPoint(double value) {
    _rawData.add(value);

    // Keep only last 900 points (30 seconds at 30 FPS)
    if (_rawData.length > 900) {
      _rawData.removeAt(0);
    }

    // Apply bandpass filter
    double filtered = _applyButterworthFilter(value);
    _filteredData.add(filtered);

    if (_filteredData.length > 900) {
      _filteredData.removeAt(0);
    }

    // Apply moving average for smoother visualization
    double averaged = _applyMovingAverage(filtered);
    _movingAverage.add(averaged);

    if (_movingAverage.length > 900) {
      _movingAverage.removeAt(0);
    }

    return averaged;
  }

  /// Apply Butterworth bandpass filter
  double _applyButterworthFilter(double input) {
    // Shift history
    for (int i = _xHistory.length - 1; i > 0; i--) {
      _xHistory[i] = _xHistory[i - 1];
      _yHistory[i] = _yHistory[i - 1];
    }

    _xHistory[0] = input;

    // Apply filter equation
    double output = 0;
    for (int i = 0; i < _bCoeff.length; i++) {
      output += _bCoeff[i] * _xHistory[i];
    }
    for (int i = 1; i < _aCoeff.length; i++) {
      output -= _aCoeff[i] * _yHistory[i];
    }

    _yHistory[0] = output;
    return output;
  }

  /// Apply moving average smoothing
  double _applyMovingAverage(double value, {int windowSize = 5}) {
    if (_filteredData.length < windowSize) return value;

    double sum = 0;
    int start = math.max(0, _filteredData.length - windowSize);
    for (int i = start; i < _filteredData.length; i++) {
      sum += _filteredData[i];
    }
    return sum / windowSize;
  }

  /// Detect peaks and calculate BPM
  BPMResult calculateBPM() {
    if (_movingAverage.length < 60) {
      return BPMResult(bpm: 0, confidence: 0, peaks: []);
    }

    List<int> peaks = _detectPeaks();

    if (peaks.length < 2) {
      return BPMResult(bpm: 0, confidence: 0, peaks: peaks);
    }

    // Calculate intervals between peaks
    List<double> intervals = [];
    for (int i = 1; i < peaks.length; i++) {
      double interval = (peaks[i] - peaks[i - 1]) / _samplingRate;
      intervals.add(interval);
    }

    // Filter out unrealistic intervals (0.25-2 seconds = 30-240 BPM)
    intervals = intervals
        .where((interval) => interval >= 0.25 && interval <= 2.0)
        .toList();

    if (intervals.isEmpty) {
      return BPMResult(bpm: 0, confidence: 0, peaks: peaks);
    }

    // Calculate average interval and convert to BPM
    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    int bpm = (60.0 / avgInterval).round();

    // Calculate confidence based on interval consistency
    double confidence = _calculateConfidence(intervals);

    return BPMResult(bpm: bpm, confidence: confidence, peaks: peaks);
  }

  /// Detect peaks in the filtered signal
  List<int> _detectPeaks() {
    List<int> peaks = [];
    if (_movingAverage.length < 10) return peaks;

    // Calculate dynamic threshold
    double mean =
        _movingAverage.reduce((a, b) => a + b) / _movingAverage.length;
    double variance = 0;
    for (double value in _movingAverage) {
      variance += math.pow(value - mean, 2);
    }
    double stdDev = math.sqrt(variance / _movingAverage.length);
    double threshold = mean + stdDev * 0.5;

    // Find peaks with minimum distance constraint
    int minDistance = (0.4 * _samplingRate).round(); // Min 400ms between peaks
    int lastPeak = -minDistance;

    for (int i = 1; i < _movingAverage.length - 1; i++) {
      if (_movingAverage[i] > threshold &&
          _movingAverage[i] > _movingAverage[i - 1] &&
          _movingAverage[i] > _movingAverage[i + 1] &&
          i - lastPeak >= minDistance) {
        peaks.add(i);
        lastPeak = i;
      }
    }

    return peaks;
  }

  /// Calculate confidence score based on interval consistency
  double _calculateConfidence(List<double> intervals) {
    if (intervals.length < 2) return 0.0;

    double mean = intervals.reduce((a, b) => a + b) / intervals.length;
    double variance = 0;
    for (double interval in intervals) {
      variance += math.pow(interval - mean, 2);
    }
    double stdDev = math.sqrt(variance / intervals.length);

    // Confidence is inversely related to standard deviation
    double coefficient = stdDev / mean;
    double confidence = math.max(0, 1.0 - (coefficient * 5));

    return math.min(1.0, confidence);
  }

  /// Get current waveform data for visualization
  List<double> getWaveformData({int maxPoints = 150}) {
    if (_movingAverage.isEmpty) return [];

    int start = math.max(0, _movingAverage.length - maxPoints);
    return _movingAverage.sublist(start);
  }

  /// Reset all data
  void reset() {
    _rawData.clear();
    _filteredData.clear();
    _movingAverage.clear();

    _xHistory.fillRange(0, _xHistory.length, 0);
    _yHistory.fillRange(0, _yHistory.length, 0);
  }
}

class BPMResult {
  final int bpm;
  final double confidence;
  final List<int> peaks;

  BPMResult({
    required this.bpm,
    required this.confidence,
    required this.peaks,
  });
}
