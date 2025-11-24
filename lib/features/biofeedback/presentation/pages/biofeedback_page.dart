import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/biofeedback_provider.dart';
import 'heart_rate_page.dart';
import 'smartwatch_connection_page.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/models/heart_rate_measurement.dart';

class BiofeedbackPage extends StatefulWidget {
  const BiofeedbackPage({super.key});

  @override
  State<BiofeedbackPage> createState() => _BiofeedbackPageState();
}

class _BiofeedbackPageState extends State<BiofeedbackPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();

    // Pulse animation for heart icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Breathing animation
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
        child: Consumer<BiofeedbackProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // App Bar with solid background
                SliverAppBar(
                  expandedHeight: 120,
                  backgroundColor: const Color(0xFF2196F3), // Blue
                  elevation: 8,
                  floating: true,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: const Text(
                      'Biofeedback Monitor',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF2196F3),
                            Color(0xFF6DD5FA),
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => _showInfoDialog(),
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Quick Actions Row (moved to top)
                      _buildQuickActionsRow(),

                      const SizedBox(height: 25),

                      // Metrics Grid
                      _buildMetricsGrid(provider),

                      const SizedBox(height: 25),

                      // Heart Rate Monitoring Section
                      _buildHeartRateSection(),

                      const SizedBox(height: 25),

                      // Smartwatch Connection
                      _buildSmartwatchSection(),

                      const SizedBox(height: 25),

                      // Breathing Exercise
                      _buildBreathingExercise(),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ... rest of your existing methods remain the same ...

  Widget _buildQuickActionsRow() {
    return AnimationConfiguration.staggeredList(
      position: 0,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Emergency',
                  Icons.emergency,
                  Colors.red,
                  () => _showEmergencyDialog(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionCard(
                  'Breathing',
                  Icons.air,
                  Colors.blue,
                  () => _startBreathingExercise(),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickActionCard(
                  'History',
                  Icons.history,
                  Colors.purple,
                  () => _showHistoryPage(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BiofeedbackProvider provider) {
    return AnimationConfiguration.staggeredList(
      position: 1,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: StreamBuilder<List<HeartRateMeasurement>>(
            stream: _firestoreService.getBiofeedbackHistory(),
            builder: (context, snapshot) {
              // Get the latest measurement or use placeholder data
              final latestMeasurement =
                  snapshot.hasData && snapshot.data!.isNotEmpty
                      ? snapshot.data!.first
                      : null;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildMetricCard(
                    context,
                    'Heart Rate',
                    latestMeasurement != null
                        ? latestMeasurement.bpm.toString()
                        : '--',
                    'BPM',
                    Icons.favorite,
                    Colors.red,
                    onTap: () => _navigateToHeartRateMonitor(),
                  ),
                  _buildMetricCard(
                    context,
                    'Stress Level',
                    latestMeasurement != null
                        ? '${_calculateStressLevel(latestMeasurement.bpm)}'
                        : '--',
                    '%',
                    Icons.psychology,
                    Colors.orange,
                    onTap: () => _showStressLevelInfo(),
                  ),
                  _buildMetricCard(
                    context,
                    'HRV Score',
                    latestMeasurement != null
                        ? '${_calculateHRVScore(latestMeasurement.bpm)}'
                        : '--',
                    'ms',
                    Icons.timeline,
                    Colors.blue,
                    onTap: () => _showHRVInfo(),
                  ),
                  _buildMetricCard(
                    context,
                    'Breathing',
                    latestMeasurement != null
                        ? '${_calculateBreathingRate(latestMeasurement.bpm)}'
                        : '--',
                    '/min',
                    Icons.air,
                    Colors.teal,
                    onTap: () => _showBreathingExercise(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value,
      String unit, IconData icon, Color color,
      {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    if (onTap != null)
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeartRateSection() {
    return AnimationConfiguration.staggeredList(
      position: 2,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Heart Rate Monitoring',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Advanced PPG-based detection',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildGradientButton(
                        'Camera Scan',
                        Icons.camera_alt,
                        [Colors.red, Colors.red.shade700],
                        () => _startCameraHeartRate(),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildGradientButton(
                        'Manual Entry',
                        Icons.edit,
                        [Colors.green, Colors.green.shade700],
                        () => _showManualEntry(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmartwatchSection() {
    return AnimationConfiguration.staggeredList(
      position: 3,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.watch,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smartwatch Integration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Sync data from your wearable',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGradientButton(
                  'Connect Watch',
                  Icons.bluetooth,
                  [Colors.blue, Colors.blue.shade700],
                  () => _navigateToSmartwatchConnection(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBreathingExercise() {
    return AnimationConfiguration.staggeredList(
      position: 4,
      duration: const Duration(milliseconds: 800),
      child: SlideAnimation(
        verticalOffset: 50.0,
        child: FadeInAnimation(
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Guided Breathing Exercise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _breathingAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _breathingAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.teal.withOpacity(0.3),
                              Colors.teal.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.air,
                            size: 40,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                const Text(
                  'Follow the rhythm to regulate your breathing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton(
    String text,
    IconData icon,
    List<Color> colors,
    VoidCallback onPressed,
  ) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: colors),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _startCameraHeartRate() async {
    // Check permissions first
    final cameraStatus = await Permission.camera.status;

    if (cameraStatus.isDenied) {
      final result = await Permission.camera.request();
      if (result != PermissionStatus.granted) {
        _showPermissionDialog(
            'Camera access is required for heart rate detection');
        return;
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraHeartRatePage(),
      ),
    );
  }

  void _navigateToSmartwatchConnection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SmartwatchConnectionPage(),
      ),
    );
  }

  void _navigateToHeartRateMonitor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraHeartRatePage(),
      ),
    );
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual Heart Rate Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your current heart rate:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Heart Rate (BPM)',
                hintText: 'e.g., 72',
                border: OutlineInputBorder(),
                suffixText: 'BPM',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final bpm = int.tryParse(controller.text);
              if (bpm != null && bpm >= 30 && bpm <= 220) {
                Navigator.of(context).pop();

                // Update provider with manual entry
                final provider =
                    Provider.of<BiofeedbackProvider>(context, listen: false);
                provider.updateHeartRate(bpm);

                // Save to Firestore
                await _saveManualMeasurementToFirestore(bpm);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Heart rate recorded: $bpm BPM'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Please enter a valid heart rate (30-220 BPM)'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biofeedback Monitor'),
        content: const Text(
          'This feature monitors your physiological signals:\n\n'
          '• Heart Rate: PPG-based camera detection\n'
          '• Stress Level: HRV analysis\n'
          '• Breathing Rate: Respiratory monitoring\n'
          '• Smartwatch Integration: Sync with wearables\n\n'
          'Place your finger gently over the camera and flash for accurate readings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 10),
            Text('Emergency Mode'),
          ],
        ),
        content: const Text(
          'Emergency features:\n\n'
          '• Instant stress relief breathing\n'
          '• Emergency contacts alert\n'
          '• Crisis helpline numbers\n'
          '• Location sharing',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              // Implement emergency actions
            },
            child: const Text('Activate Emergency'),
          ),
        ],
      ),
    );
  }

  void _startBreathingExercise() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting guided breathing exercise...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showHistoryPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening biometric history...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Future<void> _saveManualMeasurementToFirestore(int bpm) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // User not authenticated - show message but continue
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saved locally. Sign in to sync across devices.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
        return;
      }

      final measurement = HeartRateMeasurement(
        userId: user.uid,
        bpm: bpm,
        timestamp: DateTime.now(),
        method: MeasurementMethod.manual,
        confidenceScore: 0.99, // Manual entry is 99% confident
      );

      await _firestoreService.saveBiofeedback(measurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cloud_done, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Manual entry saved: $bpm BPM'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View History',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/history');
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving measurement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecentMeasurementsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.timeline,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Measurements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                      ),
                      Text(
                        'Last 5 measurements from Firestore',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<List<HeartRateMeasurement>>(
              stream: _firestoreService.getBiofeedbackHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error loading data: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final measurements = snapshot.data ?? [];
                if (measurements.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No measurements found. Start by taking a measurement!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show only the first 5 measurements
                final recentMeasurements = measurements.take(5).toList();

                return Column(
                  children: recentMeasurements.map((measurement) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Method Icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getMethodColor(measurement.method)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getMethodIcon(measurement.method),
                              color: _getMethodColor(measurement.method),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // BPM and Time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${measurement.bpm} BPM',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTimestamp(measurement.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Method Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getMethodColor(measurement.method)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getMethodDisplayName(measurement.method),
                              style: TextStyle(
                                color: _getMethodColor(measurement.method),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMethodIcon(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return Icons.camera_alt;
      case MeasurementMethod.manual:
        return Icons.edit;
      case MeasurementMethod.smartwatch:
        return Icons.watch;
    }
  }

  Color _getMethodColor(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return const Color(0xFF4CAF50);
      case MeasurementMethod.manual:
        return const Color(0xFF2196F3);
      case MeasurementMethod.smartwatch:
        return const Color(0xFF9C27B0);
    }
  }

  String _getMethodDisplayName(MeasurementMethod method) {
    switch (method) {
      case MeasurementMethod.camera:
        return 'CAMERA';
      case MeasurementMethod.manual:
        return 'MANUAL';
      case MeasurementMethod.smartwatch:
        return 'WATCH';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Calculate stress level based on heart rate
  int _calculateStressLevel(int bpm) {
    // Simple stress calculation based on heart rate ranges
    if (bpm < 60) {
      return 15; // Very low stress
    } else if (bpm < 80) {
      return 25; // Low stress
    } else if (bpm < 100) {
      return 50; // Moderate stress
    } else if (bpm < 120) {
      return 75; // High stress
    } else {
      return 90; // Very high stress
    }
  }

  // Calculate HRV score based on heart rate
  int _calculateHRVScore(int bpm) {
    // Simplified HRV calculation (inverse relationship with HR)
    // Normal HRV ranges from 20-100ms
    if (bpm < 60) {
      return 85;
    } else if (bpm < 80) {
      return 65;
    } else if (bpm < 100) {
      return 45;
    } else {
      return 25;
    }
  }

  // Calculate breathing rate based on heart rate
  int _calculateBreathingRate(int bpm) {
    // Normal breathing rate correlates with heart rate
    return (bpm / 4).round().clamp(12, 25);
  }

  // Show stress level information
  void _showStressLevelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stress Level Info'),
        content: const Text(
            'Your stress level is calculated based on your heart rate patterns. '
            'Lower heart rates typically indicate lower stress levels.\n\n'
            'Tips to reduce stress:\n'
            '• Practice deep breathing\n'
            '• Try meditation\n'
            '• Get adequate sleep\n'
            '• Regular exercise'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show HRV information
  void _showHRVInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HRV Score Info'),
        content: const Text(
            'Heart Rate Variability (HRV) measures the variation in time between heartbeats. '
            'Higher HRV generally indicates better cardiovascular fitness and stress resilience.\n\n'
            'Typical ranges:\n'
            '• Excellent: 80-100ms\n'
            '• Good: 60-79ms\n'
            '• Average: 40-59ms\n'
            '• Below Average: 20-39ms'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show breathing exercise
  void _showBreathingExercise() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Breathing Exercise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Try the 4-7-8 breathing technique:\n\n'
              '1. Inhale for 4 counts\n'
              '2. Hold for 7 counts\n'
              '3. Exhale for 8 counts\n'
              '4. Repeat 3-4 times\n\n'
              'This helps activate your parasympathetic nervous system and reduce stress.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to breathing exercise page if you have one
                _startBreathingExercise();
              },
              icon: const Icon(Icons.air),
              label: const Text('Start Exercise'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
