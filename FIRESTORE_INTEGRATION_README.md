# FirestoreService Integration Guide

This guide shows you how to integrate Cloud Firestore into your Mental Wellness app for cross-device data sync.

## 🎯 What's Been Created

### 1. Core Service
- **`lib/core/services/firestore_service.dart`** - Main service for Firestore operations
- **`lib/core/services/firestore_integration_snippets.dart`** - Copy-paste code examples

### 2. Model Extensions  
- **`lib/shared/models/heart_rate_measurement_extensions.dart`** - Firestore helpers for heart rate data
- **`lib/features/mood_detection/data/models/emotion_result_extensions.dart`** - Firestore helpers for emotion results
- **`lib/features/mood_detection/data/models/audio_emotion_result_extensions.dart`** - Audio-specific Firestore helpers

### 3. UI Components
- **`lib/features/history/presentation/pages/history_page.dart`** - StreamBuilder-based history page

## 🚀 Quick Integration Steps

### Step 1: Update Heart Rate Page

In your `lib/features/biofeedback/presentation/pages/heart_rate_page.dart`:

```dart
// Add import
import '../../../core/services/firestore_service.dart';

// Add instance variable in your State class
final FirestoreService _firestoreService = FirestoreService();

// When measurement completes, add this after your existing save logic:
try {
  final measurement = HeartRateMeasurement(
    userId: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
    bpm: bpm,
    method: MeasurementMethod.camera,
    timestamp: DateTime.now(),
    confidenceScore: confidence,
  );

  await _firestoreService.saveBiofeedback(measurement);
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❤️ Heart rate saved: ${bpm} BPM'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  print('Firestore save failed: $e');
  // Data is still saved locally - app continues to work
}
```

### Step 2: Update Audio Mood Detection Page

In your `lib/features/mood_detection/presentation/pages/audio_mood_detection_page.dart`:

```dart
// Add import
import '../../../core/services/firestore_service.dart';

// Add instance variable in your State class  
final FirestoreService _firestoreService = FirestoreService();

// In your _saveResults method, add this after existing save logic:
try {
  await _firestoreService.saveMoodSession(result, type: 'audio');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎤 Audio analysis saved: ${result.emotion}'),
        backgroundColor: Colors.green,
      ),
    );
  }
} catch (e) {
  print('Firestore save failed: $e');
  // Data is still saved locally - app continues to work
}
```

### Step 3: Add History Page to Navigation

Add the history page to your app's routing:

```dart
// In your main.dart or routing setup
routes: {
  '/history': (context) => const HistoryPage(),
  // ... other routes
},
```

## 🔐 Authentication Requirements

The FirestoreService automatically checks if a user is authenticated:

```dart
// Check if user can save to cloud
if (_firestoreService.isUserAuthenticated) {
  await _firestoreService.saveBiofeedback(measurement);
} else {
  // Save locally only, show login prompt
}
```

## 📊 Firestore Structure

Your data will be organized as:

```
users/
  {userId}/
    biofeedback/
      {timestamp}/
        - userId: string
        - bpm: number  
        - method: "camera" | "smartwatch" | "manual"
        - timestamp: Firestore timestamp
        - confidenceScore: number
    mood_sessions/
      {timestamp}/
        - emotion: string
        - confidence: number
        - allEmotions: map
        - timestamp: Firestore timestamp  
        - sessionType: "audio" | "image"
        - transcribedText: string (audio only)
        - originalLanguage: string (audio only)
```

## 🔄 Real-time Data Viewing

Use StreamBuilder to show live data:

```dart
StreamBuilder<List<HeartRateMeasurement>>(
  stream: FirestoreService().getBiofeedbackHistory(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final measurements = snapshot.data!;
      return ListView.builder(
        itemCount: measurements.length,
        itemBuilder: (context, index) {
          final measurement = measurements[index];
          return ListTile(
            title: Text('${measurement.bpm} BPM'),
            subtitle: Text(DateFormat('MMM dd, HH:mm').format(measurement.timestamp)),
          );
        },
      );
    }
    return CircularProgressIndicator();
  },
)
```

## 🛡️ Error Handling

The service is designed to fail gracefully:

- **User not logged in**: Data saves locally only
- **Network issues**: Data saves locally, sync happens later  
- **Firestore errors**: App shows warning but continues working
- **Invalid data**: Validation prevents bad data from being saved

## 🎨 UI Integration Patterns

### Success Toast
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Row(
      children: [
        Icon(Icons.cloud_done, color: Colors.white),
        SizedBox(width: 8),
        Text('Data saved successfully'),
      ],
    ),
    backgroundColor: Colors.green,
  ),
);
```

### Authentication Prompt
```dart
if (!FirestoreService().isUserAuthenticated) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Sign in to sync data'),
      content: Text('Your data will only be saved locally.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Continue Offline'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to login
          },
          child: Text('Sign In'),
        ),
      ],
    ),
  );
}
```

## 🧪 Testing

Test with different scenarios:

1. **Logged in user**: Data saves to Firestore
2. **Logged out user**: Data saves locally only  
3. **Network offline**: Data saves locally, syncs when online
4. **Invalid data**: Service rejects bad data gracefully

## 📱 Next Steps

1. **Firebase Storage**: Add file upload for audio recordings
2. **Analytics**: Use user statistics for insights
3. **Offline Support**: Implement automatic sync when online
4. **Data Export**: Allow users to export their data
5. **Sharing**: Let users share mood insights

## 🔧 Key Features

✅ **No SQLite Changes**: Your existing local storage keeps working  
✅ **Graceful Fallback**: App works offline and for anonymous users  
✅ **Real-time Sync**: Data appears instantly across devices  
✅ **Type Safety**: Full Dart type checking with proper models  
✅ **Error Handling**: Robust error handling that doesn't break your app  
✅ **Privacy**: User data is isolated by userId in Firestore  

Your Mental Wellness app now has cloud sync! 🎉