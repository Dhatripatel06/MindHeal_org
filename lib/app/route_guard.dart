import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';


class RouteGuard extends StatelessWidget {
  final Widget child;
  final String requiredFeature;
  final bool requiresBiometric;

  const RouteGuard({
    super.key,
    required this.child,
    required this.requiredFeature,
    this.requiresBiometric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Check if user is authenticated
        if (!authProvider.isAuthenticated) {
          return const Scaffold(
            body: Center(
              child: Text('Please sign in to access this feature'),
            ),
          );
        }

        // Check feature access
        if (!authProvider.hasFeatureAccess(requiredFeature)) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Denied')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'You don\'t have access to this feature',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // If biometric is required, show biometric auth
        

        // All checks passed, show the child widget
        return child;
      },
    );
  }
}
