import 'package:flutter/material.dart';

import 'data/auth/auth_service.dart';
import 'data/progress.dart';
import 'features/home/home_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/onboarding/onboarding_data.dart';
import 'services/reminders.dart';
import 'theme/app_theme.dart';

class PoppyloApp extends StatefulWidget {
  const PoppyloApp({
    super.key,
    this.progress,
    this.profile,
    this.auth,
    this.reminders,
  });

  /// Saved progress; a fresh in-memory one is used when null (tests).
  final LearningProgress? progress;

  /// Saved onboarding answers. When present the app opens on Home.
  final OnboardingData? profile;

  /// Accounts and sync; null when no backend is configured.
  final AuthService? auth;

  /// Daily practice reminders; null in tests.
  final Reminders? reminders;

  @override
  State<PoppyloApp> createState() => _PoppyloAppState();
}

class _PoppyloAppState extends State<PoppyloApp> {
  late final LearningProgress _progress = widget.progress ?? LearningProgress();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return RemindersScope(
      reminders: widget.reminders,
      child: AuthScope(
        auth: widget.auth,
        child: ProgressScope(
          progress: _progress,
          child: MaterialApp(
            title: 'Poppylo',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: profile == null
                ? const LandingScreen()
                : HomeScreen(profile: profile),
          ),
        ),
      ),
    );
  }
}
