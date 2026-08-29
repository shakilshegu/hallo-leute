import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

class FeedbackSentScreen extends StatelessWidget {
  final String meetingId;
  const FeedbackSentScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Warm beige
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Checkmark icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6EBE6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: colorScheme.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Thanks.',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "If Sarah also wants to meet again, we'll let you both know.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.primary.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 64),

              Center(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.home);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'BACK TO HOME',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Hidden test button for Mutual Connection
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.mutualConnectionPath(meetingId));
                },
                child: Text(
                  'Test Mutual Connection Screen',
                  style: TextStyle(color: colorScheme.primary.withOpacity(0.2)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
