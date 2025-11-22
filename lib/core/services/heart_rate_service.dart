import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/heart_rate_measurement.dart';

class HeartRateService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String _collection = 'heart_rate_measurements';
  
  /// Save heart rate measurement to Firestore
  static Future<String> saveMeasurement(HeartRateMeasurement measurement) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      final docRef = await _firestore
          .collection(_collection)
          .add(measurement.toJson());
          
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save measurement: $e');
    }
  }
  
  /// Get user's heart rate measurements
  static Stream<List<HeartRateMeasurement>> getUserMeasurements() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return HeartRateMeasurement.fromJson(
          doc.data(),
          doc.id,
        );
      }).toList();
    });
  }
  
  /// Get latest measurement
  static Future<HeartRateMeasurement?> getLatestMeasurement() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
          
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      return HeartRateMeasurement.fromJson(doc.data(), doc.id);
    } catch (e) {
      print('Error getting latest measurement: $e');
      return null;
    }
  }
  
  /// Delete measurement
  static Future<void> deleteMeasurement(String measurementId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(measurementId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete measurement: $e');
    }
  }
  
  /// Get average BPM over last N days
  static Future<double> getAverageBPM({int days = 7}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;
      
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final snapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .get();
          
      if (snapshot.docs.isEmpty) return 0;
      
      double total = 0;
      for (var doc in snapshot.docs) {
        total += doc.data()['bpm'] as int;
      }
      
      return total / snapshot.docs.length;
    } catch (e) {
      print('Error calculating average BPM: $e');
      return 0;
    }
  }
}
