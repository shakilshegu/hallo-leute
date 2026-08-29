import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';

class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({super.key});

  void _finishOnboarding(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.done);
    // Onboarding is done — clear the stack so the user can never swipe back
    // into OTP or any onboarding step.
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                "Don't miss your match",
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "We'll notify you when someone accepts, when a café is "
                "proposed, and right before your meeting starts.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _finishOnboarding(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Turn on notifications'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _finishOnboarding(context, ref),
                child: Text(
                  'Not now',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
