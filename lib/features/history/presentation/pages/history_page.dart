import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';
import '../../../mood_detection/data/models/emotion_result.dart';
import '../../../mood_detection/data/models/audio_emotion_result.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Your Wellness History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.favorite),
              text: 'Heart Rate',
            ),
            Tab(
              icon: Icon(Icons.psychology),
              text: 'Mood Sessions',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBiofeedbackHistory(),
          _buildMoodHistory(),
        ],
      ),
    );
  }

  Widget _buildBiofeedbackHistory() {
    return StreamBuilder<List<HeartRateMeasurement>>(
      stream: _firestoreService.getBiofeedbackHistory(),
      builder: (context, snapshot) {
        if (!_firestoreService.isUserAuthenticated) {
          return _buildNotAuthenticatedWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(
              'Error loading heart rate data: ${snapshot.error}');
        }

        final measurements = snapshot.data ?? [];

        if (measurements.isEmpty) {
          return _buildEmptyStateWidget(
            'No Heart Rate Data',
            'Start measuring your heart rate to see your history here.',
            Icons.favorite,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: measurements.length,
          itemBuilder: (context, index) {
            final measurement = measurements[index];
            return _buildBiofeedbackCard(measurement);
          },
        );
      },
    );
  }

  Widget _buildMoodHistory() {
    return StreamBuilder<List<EmotionResult>>(
      stream: _firestoreService.getMoodHistory(),
      builder: (context, snapshot) {
        if (!_firestoreService.isUserAuthenticated) {
          return _buildNotAuthenticatedWidget();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.teal),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorWidget(
              'Error loading mood data: ${snapshot.error}');
        }

        final moodSessions = snapshot.data ?? [];

        if (moodSessions.isEmpty) {
          return _buildEmptyStateWidget(
            'No Mood Sessions',
            'Complete a mood detection session to see your history here.',
            Icons.psychology,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: moodSessions.length,
          itemBuilder: (context, index) {
            final session = moodSessions[index];
            return _buildMoodSessionCard(session);
          },
        );
      },
    );
  }

  Widget _buildBiofeedbackCard(HeartRateMeasurement measurement) {
    final date = DateFormat('MMM dd, yyyy').format(measurement.timestamp);
    final time = DateFormat('hh:mm a').format(measurement.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getHeartRateColor(measurement.bpm).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getHeartRateColor(measurement.bpm),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite,
                      color: _getHeartRateColor(measurement.bpm),
                      size: 20,
                    ),
                    Text(
                      '${measurement.bpm}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getHeartRateColor(measurement.bpm),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${measurement.bpm} BPM',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getHeartRateColor(measurement.bpm),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _getHeartRateCategory(measurement.bpm),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getMeasurementMethodColor(
                                    measurement.method),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getMeasurementMethodIcon(
                                        measurement.method),
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _getMethodShortName(measurement.method),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (measurement.confidenceScore != null)
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color:
                              _getConfidenceColor(measurement.confidenceScore!),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Confidence: ${(measurement.confidenceScore! * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getConfidenceColor(
                                measurement.confidenceScore!),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$date at $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteBiofeedbackDialog(measurement),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[600],
                size: 20,
              ),
              tooltip: 'Delete measurement',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSessionCard(EmotionResult session) {
    final date = DateFormat('MMM dd, yyyy').format(session.timestamp);
    final time = DateFormat('hh:mm a').format(session.timestamp);
    final isAudio = session is AudioEmotionResult;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getEmotionColor(session.emotion).withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getEmotionColor(session.emotion),
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getEmotionEmoji(session.emotion),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.emotion.toUpperCase(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getEmotionColor(session.emotion),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isAudio ? Colors.blue : Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAudio ? 'AUDIO' : 'IMAGE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confidence: ${(session.confidence * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (isAudio)
                    // ignore: unnecessary_cast
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      // ignore: unnecessary_cast
                      child: Text(
                        '"${(session as AudioEmotionResult).transcribedText.length > 50
                            // ignore: unnecessary_cast
                            ? (session as AudioEmotionResult).transcribedText.substring(0, 50) + '...'
                            // ignore: unnecessary_cast
                            : (session as AudioEmotionResult).transcribedText}"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$date at $time',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteMoodDialog(session),
              icon: Icon(
                Icons.delete_outline,
                color: Colors.grey[600],
                size: 20,
              ),
              tooltip: 'Delete session',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAuthenticatedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to view your history',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to login page
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Trigger rebuild
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWidget(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeartRateColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm >= 60 && bpm <= 100) return Colors.green;
    if (bpm > 100 && bpm <= 140) return Colors.orange;
    return Colors.red;
  }

  String _getHeartRateCategory(int bpm) {
    if (bpm < 60) return 'Low';
    if (bpm >= 60 && bpm <= 100) return 'Normal';
    if (bpm > 100 && bpm <= 140) return 'Elevated';
    return 'High';
  }

  String _formatMeasurementMethod(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return 'Camera Scan';
      case MeasurementMethod.smartwatch:
        return 'Smartwatch';
      case MeasurementMethod.manual:
        return 'Manual Entry';
    }
  }

  IconData _getMeasurementMethodIcon(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return Icons.camera_alt;
      case MeasurementMethod.smartwatch:
        return Icons.watch;
      case MeasurementMethod.manual:
        return Icons.edit;
    }
  }

  Color _getMeasurementMethodColor(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return Colors.blue;
      case MeasurementMethod.smartwatch:
        return Colors.purple;
      case MeasurementMethod.manual:
        return Colors.orange;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getMethodShortName(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return 'CAM';
      case MeasurementMethod.smartwatch:
        return 'WATCH';
      case MeasurementMethod.manual:
        return 'MANUAL';
    }
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
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

  String _getEmotionEmoji(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
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
        return '😲';
      case 'disgust':
        return '🤢';
      case 'neutral':
        return '😐';
      default:
        return '😐';
    }
  }

  void _showDeleteBiofeedbackDialog(HeartRateMeasurement measurement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Measurement'),
          content: Text(
            'Are you sure you want to delete this heart rate measurement of ${measurement.bpm} BPM?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteBiofeedback(measurement);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteMoodDialog(EmotionResult session) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Session'),
          content: Text(
            'Are you sure you want to delete this ${session.emotion} mood session?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteMoodSession(session);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBiofeedback(HeartRateMeasurement measurement) async {
    try {
      // Convert timestamp to document ID format
      final docId = measurement.timestamp.millisecondsSinceEpoch.toString();
      await _firestoreService.deleteBiofeedbackMeasurement(docId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Heart rate measurement deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting measurement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMoodSession(EmotionResult session) async {
    try {
      // Convert timestamp to document ID format
      final docId = session.timestamp.millisecondsSinceEpoch.toString();
      await _firestoreService.deleteMoodSession(docId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mood session deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
