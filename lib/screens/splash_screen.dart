import 'package:flutter/material.dart';

/// Shown for the instant it takes the auth guard to decide where this
/// session actually belongs — signed out, mid-onboarding, or home. It never
/// stays on screen long enough to need its own navigation.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_cafe, color: colorScheme.primary, size: 48),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}
