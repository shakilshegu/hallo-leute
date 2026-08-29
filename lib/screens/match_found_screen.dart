import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';

class MatchFoundScreen extends StatefulWidget {
  final String matchId;
  const MatchFoundScreen({super.key, required this.matchId});

  @override
  State<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends State<MatchFoundScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Text(
                "It's a match",
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You both want to meet. Now choose where.',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 140,
                width: 180, // Constrain width so they overlap in the center
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFF3F1EB), width: 4),
                        ),
                        child: const CircleAvatar(
                          radius: 56,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFF3F1EB), width: 4),
                        ),
                        child: const CircleAvatar(
                          radius: 56,
                          backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCA928),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF3F1EB), width: 4),
                      ),
                      child: const Icon(Icons.favorite,
                          color: Colors.white, size: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'SATURDAY · 5:00 PM · 45 MIN',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.chooseCafePath(widget.matchId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Choose a café',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.home);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Message later',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
