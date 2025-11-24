import 'package:flutter/material.dart';
import 'package:mental_wellness_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';
import '../../../mood_detection/data/models/emotion_result.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Handle notifications
            },
          ),
          // User profile
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return PopupMenuButton<String>(
                icon: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    authProvider.user?.email?.substring(0, 1).toUpperCase() ??
                        'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'profile':
                      Navigator.pushNamed(context, '/profile');
                      break;
                    case 'settings':
                      Navigator.pushNamed(context, '/settings');
                      break;
                    case 'logout':
                      await _showLogoutDialog(context, authProvider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings_outlined),
                      title: Text('Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title:
                          Text('Sign Out', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'How are you feeling today?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildMoodButton(context, '😊', 'Great'),
                        const SizedBox(width: 8),
                        _buildMoodButton(context, '😌', 'Good'),
                        const SizedBox(width: 8),
                        _buildMoodButton(context, '😐', 'Okay'),
                        const SizedBox(width: 8),
                        _buildMoodButton(context, '😟', 'Low'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Today's Wellness Metrics
            Text(
              'Today\'s Wellness',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<HeartRateMeasurement>>(
                    stream: _firestoreService.getBiofeedbackHistory(),
                    builder: (context, snapshot) {
                      final latestBPM =
                          snapshot.hasData && snapshot.data!.isNotEmpty
                              ? snapshot.data!.first
                              : null;

                      return _buildMetricCard(
                        context,
                        'Stress Level',
                        latestBPM != null
                            ? '${_calculateStressLevel(latestBPM.bpm)}%'
                            : '--',
                        Icons.psychology,
                        Colors.orange,
                        latestBPM != null
                            ? _getStressStatus(latestBPM.bpm)
                            : 'No data',
                        onTap: () => _showStressInfo(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<List<HeartRateMeasurement>>(
                    stream: _firestoreService.getBiofeedbackHistory(),
                    builder: (context, snapshot) {
                      final latestBPM =
                          snapshot.hasData && snapshot.data!.isNotEmpty
                              ? snapshot.data!.first
                              : null;

                      return _buildMetricCard(
                        context,
                        'Heart Rate',
                        latestBPM != null ? '${latestBPM.bpm} BPM' : '-- BPM',
                        Icons.favorite,
                        Colors.red,
                        latestBPM != null
                            ? _getHeartRateStatus(latestBPM.bpm)
                            : 'No data',
                        onTap: () =>
                            Navigator.pushNamed(context, '/biofeedback'),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<EmotionResult>>(
                    stream: _firestoreService.getMoodHistory(),
                    builder: (context, snapshot) {
                      final latestMood =
                          snapshot.hasData && snapshot.data!.isNotEmpty
                              ? snapshot.data!.first
                              : null;

                      return _buildMetricCard(
                        context,
                        'Mood Score',
                        latestMood != null
                            ? '${(latestMood.confidence * 10).toStringAsFixed(1)}/10'
                            : '--/10',
                        Icons.mood,
                        Colors.green,
                        latestMood?.emotion ?? 'No data',
                        onTap: () => _showMoodInfo(),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<List<EmotionResult>>(
                    stream: _firestoreService.getMoodHistory(),
                    builder: (context, snapshot) {
                      final latestMood =
                          snapshot.hasData && snapshot.data!.isNotEmpty
                              ? snapshot.data!.first
                              : null;

                      return _buildMetricCard(
                        context,
                        'Latest Mood',
                        latestMood?.emotion ?? '--',
                        Icons.sentiment_satisfied,
                        _getMoodColor(latestMood?.emotion),
                        latestMood != null
                            ? '${(latestMood.confidence * 100).toInt()}% confident'
                            : 'No data',
                        onTap: () =>
                            Navigator.pushNamed(context, '/mood-detection'),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  'Mood Tracking',
                  Icons.psychology,
                  Theme.of(context).colorScheme.primary,
                  '/mood-tracking',
                ),
                _buildActionCard(
                  context,
                  'Heart Rate',
                  Icons.favorite,
                  Colors.red,
                  '/biofeedback',
                ),
                _buildActionCard(
                  context,
                  'Wellness History',
                  Icons.history,
                  Theme.of(context).colorScheme.tertiary,
                  '/history',
                ),
                _buildActionCard(
                  context,
                  'Wellness Chat',
                  Icons.chat,
                  Colors.teal,
                  '/chat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(
      BuildContext context, AuthProvider authProvider) async {
    return showDialog(
      context: this.context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.signOut();
              // Navigation will be handled by AuthWrapper
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

Widget _buildMoodButton(BuildContext context, String emoji, String label) {
  return Expanded(
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[100],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMetricCard(BuildContext context, String title, String value,
    IconData icon, Color color, String status,
    {VoidCallback? onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              status,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

void _showStressInfo() {
  // Info displayed through console for now
  // Stress level calculated from heart rate patterns
  print('=== STRESS LEVEL INFO ===');
  print('Tips to manage stress:');
  print('• Practice deep breathing');
  print('• Try meditation');
  print('• Get adequate sleep');
  print('• Regular exercise');
}

void _showMoodInfo() {
  // Info displayed through console for now
  // Based on latest emotion detection results
  print('=== MOOD TRACKING INFO ===');
  print('Track your mood regularly to:');
  print('• Identify patterns');
  print('• Monitor progress');
  print('• Get personalized insights');
  print('• Improve mental wellness');
}

Widget _buildActionCard(BuildContext context, String title, IconData icon,
    Color color, String route) {
  return Card(
    child: InkWell(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

// Calculate stress level based on heart rate
int _calculateStressLevel(int bpm) {
  if (bpm < 60) {
    return 15;
  } else if (bpm < 80) {
    return 25;
  } else if (bpm < 100) {
    return 50;
  } else if (bpm < 120) {
    return 75;
  } else {
    return 90;
  }
}

String _getStressStatus(int bpm) {
  final stress = _calculateStressLevel(bpm);
  if (stress < 30) {
    return 'Low';
  } else if (stress < 60) {
    return 'Moderate';
  } else {
    return 'High';
  }
}

String _getHeartRateStatus(int bpm) {
  if (bpm < 60) {
    return 'Below Normal';
  } else if (bpm <= 100) {
    return 'Normal';
  } else {
    return 'Elevated';
  }
}

Color _getMoodColor(String? emotion) {
  switch (emotion?.toLowerCase()) {
    case 'happy':
    case 'joy':
      return Colors.green;
    case 'sad':
    case 'sadness':
      return Colors.blue;
    case 'angry':
    case 'anger':
      return Colors.red;
    case 'fear':
    case 'anxiety':
      return Colors.orange;
    case 'surprise':
      return Colors.purple;
    case 'neutral':
      return Colors.grey;
    default:
      return Colors.teal;
  }
}
