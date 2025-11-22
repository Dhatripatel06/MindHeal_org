import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_state.dart';
import '../pages/login_page.dart';
import '../pages/email_verification_page.dart';
import '../../../navigation/presentation/pages/main_navigation_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        switch (authProvider.state.status) {
          case AuthStatus.loading:
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
            
          case AuthStatus.authenticated:
            return const MainNavigationPage();
            
          case AuthStatus.emailNotVerified:
            return const EmailVerificationPage();
            
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
          default:
            return const LoginPage();
        }
      },
    );
  }
}
