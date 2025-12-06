import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';

class BiofeedbackHistoryPage extends StatefulWidget {
  const BiofeedbackHistoryPage({super.key});

  @override
  State<BiofeedbackHistoryPage> createState() => _BiofeedbackHistoryPageState();
}

class _BiofeedbackHistoryPageState extends State<BiofeedbackHistoryPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String _filterPeriod = 'All Time';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biofeedback History'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'This Week', child: Text('This Week')),
              const PopupMenuItem(
                  value: 'This Month', child: Text('This Month')),
              const PopupMenuItem(value: 'All Time', child: Text('All Time')),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Filter indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Showing: $_filterPeriod',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // History list
            Expanded(
              child: StreamBuilder<List<HeartRateMeasurement>>(
                stream: _firestoreService.getBiofeedbackHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.blue),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No biofeedback history yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start measuring your heart rate!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  List<HeartRateMeasurement> filteredData =
                      _filterData(snapshot.data!);

                  if (filteredData.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_list_off,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No data for $_filterPeriod',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final measurement = filteredData[index];
                      return _buildHistoryCard(measurement);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<HeartRateMeasurement> _filterData(List<HeartRateMeasurement> data) {
    final now = DateTime.now();

    switch (_filterPeriod) {
      case 'Today':
        return data.where((m) {
          final diff = now.difference(m.timestamp);
          return diff.inHours < 24;
        }).toList();
      case 'This Week':
        return data.where((m) {
          final diff = now.difference(m.timestamp);
          return diff.inDays < 7;
        }).toList();
      case 'This Month':
        return data.where((m) {
          final diff = now.difference(m.timestamp);
          return diff.inDays < 30;
        }).toList();
      case 'All Time':
      default:
        return data;
    }
  }

  Widget _buildHistoryCard(HeartRateMeasurement measurement) {
    final stressLevel = _calculateStressLevel(measurement.bpm);
    final stressStatus = _getStressStatus(measurement.bpm);
    final color = _getStressColor(measurement.bpm);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy')
                              .format(measurement.timestamp),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('hh:mm a').format(measurement.timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Method badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getMethodColor(measurement.method).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          _getMethodColor(measurement.method).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMethodIcon(measurement.method),
                        size: 16,
                        color: _getMethodColor(measurement.method),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getMethodDisplayName(measurement.method),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getMethodColor(measurement.method),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                // Heart Rate
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.favorite, color: Colors.red, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          '${measurement.bpm}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          'BPM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stress Level
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.psychology, color: color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          '$stressLevel%',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          stressStatus,
                          style: TextStyle(
                            fontSize: 11,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _calculateStressLevel(int bpm) {
    if (bpm < 60) return 15;
    if (bpm < 70) return 25;
    if (bpm < 80) return 40;
    if (bpm < 90) return 55;
    if (bpm < 100) return 70;
    return 85;
  }

  String _getStressStatus(int bpm) {
    if (bpm < 60) return 'Very Low';
    if (bpm < 70) return 'Low';
    if (bpm < 80) return 'Normal';
    if (bpm < 90) return 'Moderate';
    if (bpm < 100) return 'High';
    return 'Very High';
  }

  Color _getStressColor(int bpm) {
    if (bpm < 60) return Colors.blue;
    if (bpm < 70) return Colors.green;
    if (bpm < 80) return Colors.lightBlue;
    if (bpm < 90) return Colors.orange;
    if (bpm < 100) return Colors.deepOrange;
    return Colors.red;
  }

  IconData _getMethodIcon(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return Icons.camera_alt;
      case MeasurementMethod.manual:
        return Icons.edit;
    }
  }

  Color _getMethodColor(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return const Color(0xFF4CAF50);
      case MeasurementMethod.manual:
        return const Color(0xFF2196F3);
    }
  }

  String _getMethodDisplayName(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return 'CAMERA';
      case MeasurementMethod.manual:
        return 'MANUAL';
    }
  }
}
