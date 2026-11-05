import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/home/home_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/learn/session_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/placeholders/coming_soon_screens.dart';
import 'features/shell/app_shell.dart';
import 'screens/start_screen.dart';

abstract final class Routes {
  static const welcome = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const learn = '/learn';
  static const review = '/review';
  static const profile = '/profile';
  static const session = '/session';
}

/// Fade-through page transition used between top-level screens.
CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondary,
            fillColor: Colors.transparent,
            child: child,
          ),
    );

GoRoute _tab(String path, Widget screen) => GoRoute(
  path: path,
  pageBuilder: (context, state) => NoTransitionPage(child: screen),
);

GoRouter createRouter({String initialLocation = Routes.welcome}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: Routes.welcome,
      pageBuilder: (context, state) => _fadeThrough(state, const StartScreen()),
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) =>
          _fadeThrough(state, const OnboardingScreen()),
    ),
    // Flashcard session: full screen above the tabs, slides up.
    GoRoute(
      path: Routes.session,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: SessionScreen(topic: state.uri.queryParameters['topic']),
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        transitionsBuilder: (context, animation, secondary, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    ),
    // Main app: four tabs inside the Bloom Dock shell.
    StatefulShellRoute(
      pageBuilder: (context, state, shell) =>
          _fadeThrough(state, AppShell(shell: shell)),
      navigatorContainerBuilder: (context, shell, children) =>
          FadingBranches(currentIndex: shell.currentIndex, children: children),
      branches: [
        StatefulShellBranch(routes: [_tab(Routes.home, const HomeScreen())]),
        StatefulShellBranch(routes: [_tab(Routes.learn, const LearnScreen())]),
        StatefulShellBranch(
          routes: [_tab(Routes.review, const ReviewScreen())],
        ),
        StatefulShellBranch(
          routes: [_tab(Routes.profile, const ProfileScreen())],
        ),
      ],
    ),
  ],
);
