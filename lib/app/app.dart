import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mental_wellness_app/features/auth/presentation/pages/email_verification_page.dart';
import 'package:mental_wellness_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mental_wellness_app/features/settings/presentation/pages/settings_page.dart';
import 'package:provider/provider.dart';

// Authentication imports
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/widgets/auth_wrapper.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';

// Mood Detection imports - ADD THESE
import '../features/mood_detection/presentation/pages/mood_selection_page.dart';
import '../features/mood_detection/presentation/providers/mood_detection_provider.dart';
import '../features/mood_detection/presentation/providers/image_detection_provider.dart';
import '../features/mood_detection/presentation/providers/audio_detection_provider.dart';
import '../features/mood_detection/presentation/providers/combined_detection_provider.dart';
import 'route_guard.dart';

// Services
import '../core/services/firebase_auth_service.dart';

// Datasources & Repository
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';

// UseCases
import '../features/auth/domain/usecases/sign_in_with_email.dart';
import '../features/auth/domain/usecases/sign_in_with_google.dart';
import '../features/auth/domain/usecases/sign_in_anonymously.dart';
import '../features/auth/domain/usecases/sign_out.dart';

// Other features
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/biofeedback/presentation/pages/biofeedback_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/audio_healing/presentation/pages/audio_healing_page.dart';
import '../features/biofeedback/presentation/providers/biofeedback_provider.dart';
import '../features/biofeedback/presentation/providers/camera_heart_rate_provider.dart';
import '../core/services/gemini_adviser_service.dart';



// Theme
import 'theme.dart';

class AssetDebugService {
  static Future<void> checkAssets() async {
    print('🔍 Checking asset availability...');

    // List of assets to check
    final assetsToCheck = [
      'models/fer2013_model_direct.tflite',
      'models/labels.txt',
    ];

    for (final asset in assetsToCheck) {
      try {
        final data = await rootBundle.load(asset);
        print('✅ Asset found: $asset (${data.lengthInBytes} bytes)');
      } catch (e) {
        print('❌ Asset missing: $asset - Error: $e');
      }
    }

    // Try to read labels file content
    try {
      final labelsContent = await rootBundle.loadString('models/labels.txt');
      print('📝 Labels content: $labelsContent');
    } catch (e) {
      print('❌ Cannot read labels file: $e');
    }
  }
}

class MentalWellnessApp extends StatelessWidget {
  const MentalWellnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔥 FIXED: Remove duplicate and add missing providers
        ChangeNotifierProvider(create: (_) => MoodDetectionProvider()),
        ChangeNotifierProvider(create: (_) => ImageDetectionProvider()),
        ChangeNotifierProvider(create: (_) => AudioDetectionProvider()),
        ChangeNotifierProvider(create: (_) => CombinedDetectionProvider(
          imageProvider: Provider.of<ImageDetectionProvider>(context),
          audioProvider: Provider.of<AudioDetectionProvider>(context),
          geminiService: GeminiAdviserService(),

        )),


        // Biofeedback providers
        ChangeNotifierProvider(create: (_) => BiofeedbackProvider()),
        ChangeNotifierProvider(create: (_) => CameraHeartRateProvider()),

        // Authentication Provider
        ChangeNotifierProvider(
          create: (context) {
            final authService = FirebaseAuthService();
            final authDataSource = AuthRemoteDataSourceImpl(
              authService: authService,
            );
            final authRepository = AuthRepositoryImpl(
              remoteDataSource: authDataSource,
            );
            return AuthProvider(
              authRepository: authRepository,
              signInWithEmail: SignInWithEmail(authRepository),
              signInWithGoogle: SignInWithGoogle(authRepository),
              signInAnonymously: SignInAnonymously(authRepository),
              signOut: SignOut(authRepository),
            );
          },
        ),
      ],
      child: MaterialApp(
        title: 'Mental Wellness',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/email-verification': (context) => const EmailVerificationPage(),
          "/profile": (context) => const ProfilePage(),
          '/settings': (context) => const SettingsPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/audio-healing': (context) => const AudioHealingPage(),
          '/mood-tracking': (context) => RouteGuard(
                requiredFeature: 'mood_tracking',
                child: const MoodSelectionPage(),
              ),
          '/biofeedback': (context) => RouteGuard(
                requiredFeature: 'biofeedback',
                child: const BiofeedbackPage(),
              ),
          '/chat': (context) =>
              RouteGuard(requiredFeature: 'chat', child: const ChatPage()),
        },
      ),
    );
  }
}
