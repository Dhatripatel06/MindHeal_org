/// FIRESTORE INTEGRATION GUIDE
///
/// This file provides examples for integrating the FirestoreService
/// Follow the code examples below to add cloud sync to your Mental Wellness app.

/// ==================== 1. HEART RATE PAGE INTEGRATION ====================
///
/// Add this to your heart_rate_page.dart imports:
/// ```dart
/// import '../../../../core/services/firestore_service.dart';
/// import 'package:firebase_auth/firebase_auth.dart';
/// ```
///
/// Add this instance variable to your State class:
/// ```dart
/// final FirestoreService _firestoreService = FirestoreService();
/// ```
///
/// Add this method to save heart rate measurements:
/// ```dart
/// Future<void> _saveHeartRateMeasurement() async {
///   try {
///     final user = FirebaseAuth.instance.currentUser;
///     if (user == null) {
///       print('User not authenticated - skipping Firestore save');
///       return;
///     }
///
///     final measurement = HeartRateMeasurement(
///       userId: user.uid,
///       bpm: _currentBPM,
///       method: MeasurementMethod.camera,
///       timestamp: DateTime.now(),
///       confidenceScore: _confidence,
///       metadata: {
///         'sessionDuration': _progress,
///         'device': 'camera',
///       },
///     );
///
///     await _firestoreService.saveBiofeedback(measurement);
///
///     if (mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Row(
///             children: [
///               const Icon(Icons.cloud_done, color: Colors.white),
///               const SizedBox(width: 8),
///               Text('Heart rate saved: $_currentBPM BPM'),
///             ],
///           ),
///           backgroundColor: Colors.green,
///         ),
///       );
///     }
///   } catch (e) {
///     print('Firestore save failed: $e');
///     if (mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         const SnackBar(
///           content: Text('Saved locally. Cloud sync failed.'),
///           backgroundColor: Colors.orange,
///         ),
///       );
///     }
///   }
/// }
/// ```

/// ==================== 2. AUDIO MOOD DETECTION PAGE INTEGRATION ====================
///
/// Add this to your audio_mood_detection_page.dart imports:
/// ```dart
/// import '../../../../core/services/firestore_service.dart';
/// import 'package:firebase_auth/firebase_auth.dart';
/// ```
///
/// Add this instance variable to your State class:
/// ```dart
/// final FirestoreService _firestoreService = FirestoreService();
/// ```
///
/// Add this method to save mood session data:
/// ```dart
/// Future<void> _saveMoodSessionToFirestore(result) async {
///   try {
///     final user = FirebaseAuth.instance.currentUser;
///     if (user == null) {
///       if (mounted) {
///         ScaffoldMessenger.of(context).showSnackBar(
///           const SnackBar(
///             content: Text('Saved locally. Sign in to sync across devices.'),
///             backgroundColor: Colors.blue,
///           ),
///         );
///       }
///       return;
///     }
///
///     await _firestoreService.saveMoodSession(result, type: 'audio');
///
///     if (mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Row(
///             children: [
///               const Icon(Icons.cloud_done, color: Colors.white),
///               const SizedBox(width: 8),
///               Text('Audio analysis saved: ${result.emotion}'),
///             ],
///           ),
///           backgroundColor: Colors.green,
///           action: SnackBarAction(
///             label: 'View History',
///             textColor: Colors.white,
///             onPressed: () => Navigator.pushNamed(context, '/history'),
///           ),
///         ),
///       );
///     }
///   } catch (e) {
///     print('Firestore save failed: $e');
///     if (mounted) {
///       ScaffoldMessenger.of(context).showSnackBar(
///         SnackBar(
///           content: Text('Saved locally. Cloud sync failed: $e'),
///           backgroundColor: Colors.orange,
///         ),
///       );
///     }
///   }
/// }
/// ```

/// ==================== 3. FIRESTORE RULES DEPLOYMENT ====================
///
/// The firestore.rules file has been created in the project root.
/// Deploy it using one of these methods:
///
/// Method 1 - Firebase CLI:
/// ```bash
/// firebase deploy --only firestore:rules
/// ```
///
/// Method 2 - Firebase Console:
/// 1. Go to https://console.firebase.google.com
/// 2. Select your project
/// 3. Go to Firestore Database > Rules
/// 4. Copy the rules from firestore.rules and paste them
/// 5. Click "Publish"

/// ==================== 4. REAL-TIME DATA USAGE ====================
///
/// Use StreamBuilder in your UI components for real-time updates:
/// ```dart
/// StreamBuilder<List<HeartRateMeasurement>>(
///   stream: FirestoreService().getBiofeedbackHistory(),
///   builder: (context, snapshot) {
///     if (snapshot.connectionState == ConnectionState.waiting) {
///       return const CircularProgressIndicator();
///     }
///
///     if (snapshot.hasError) {
///       return Text('Error: ${snapshot.error}');
///     }
///
///     final measurements = snapshot.data ?? [];
///     return ListView.builder(
///       itemCount: measurements.length,
///       itemBuilder: (context, index) {
///         final measurement = measurements[index];
///         return ListTile(
///           title: Text('${measurement.bpm} BPM'),
///           subtitle: Text(DateFormat('MMM dd, HH:mm').format(measurement.timestamp)),
///         );
///       },
///     );
///   },
/// )
/// ```

void main() {
  // This is a documentation file - not meant to be executed
  print('📚 Firestore Integration Documentation');
  print('Review the comments above for integration examples.');
}
