import 'package:flutter/material.dart';

import 'data/auth/auth_service.dart';
import 'data/progress.dart';
import 'data/vocabulary.dart';
import 'features/home/home_content.dart';
import 'features/home/home_screen.dart';
import 'features/lesson/lesson_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/onboarding/onboarding_data.dart';
import 'services/reminders.dart';
import 'theme/app_theme.dart';

class HalloLeuteApp extends StatefulWidget {
  const HalloLeuteApp({
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
  State<HalloLeuteApp> createState() => _HalloLeuteAppState();
}

class _HalloLeuteAppState extends State<HalloLeuteApp> {
  late final LearningProgress _progress = widget.progress ?? LearningProgress();
  late bool _practisedToday = _progress.practisedToday;
  final _navigator = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _progress.addListener(_onProgress);
    _reschedule();
    widget.reminders?.openedWord.addListener(_openTappedWord);
    widget.reminders?.checkLaunch();
  }

  /// A word pop-up was tapped: show that word as a flashcard.
  void _openTappedWord() {
    final reminders = widget.reminders!;
    final key = reminders.openedWord.value;
    if (key == null) return;
    final navigator = _navigator.currentState;
    if (navigator == null) {
      // Cold start: wait for the first frame, then try again.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openTappedWord());
      return;
    }
    reminders.openedWord.value = null;
    final word = vocabulary
        .where((w) => LearningProgress.keyOf(w) == key)
        .firstOrNull;
    if (word != null) navigator.push(LessonScreen.route([word]));
  }

  /// After the first answer of the day, today's reminder is no longer
  /// needed, and pop-ups skip words that were just learned.
  void _onProgress() {
    final now = _progress.practisedToday;
    if (now != _practisedToday) {
      _practisedToday = now;
      _reschedule();
    }
  }

  void _reschedule() {
    final reminders = widget.reminders;
    if (reminders == null) return;
    reminders.reschedule(
      practisedToday: _progress.practisedToday,
      streak: _progress.streak,
    );
    reminders.reschedulePopups(
      wordsFor: (day) => wordsForDay(day, level: _progress.studyLevel),
      isLearned: _progress.isLearned,
    );
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgress);
    widget.reminders?.openedWord.removeListener(_openTappedWord);
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
            title: 'Hallo Leute',
            navigatorKey: _navigator,
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
