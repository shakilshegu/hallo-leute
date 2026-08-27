import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/features/onboarding/onboarding_screen.dart';
import 'package:poppylo/features/auth/login_screen.dart';
import 'package:poppylo/features/home/home_screen.dart';
import 'package:poppylo/features/home/concepts/concepts_picker_screen.dart';
import 'package:poppylo/features/home/concepts/premium_home_screen.dart';
import 'package:poppylo/features/home/concepts/adventure_home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home', // TEMP: for screenshot verification, revert to '/onboarding'
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Dev-only routes for comparing the three homepage concepts.
      GoRoute(
        path: '/concepts',
        builder: (context, state) => const ConceptsPickerScreen(),
      ),
      GoRoute(
        path: '/concepts/premium',
        builder: (context, state) => const PremiumHomeScreen(),
      ),
      GoRoute(
        path: '/concepts/adventure',
        builder: (context, state) => const AdventureHomeScreen(),
      ),
    ],
  );
});
