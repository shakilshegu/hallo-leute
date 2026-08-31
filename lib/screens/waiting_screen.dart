import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/match_controller.dart';

/// The "waiting for the other person to accept" state. Once they do (here,
/// simulated with a timer since there's no second device), the match is
/// marked accepted and this screen is replaced by [MatchConfirmedScreen] —
/// waiting shouldn't linger in the back stack once it's no longer true.
class MatchStatusScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchStatusScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchStatusScreen> createState() => _MatchStatusScreenState();
}

class _MatchStatusScreenState extends ConsumerState<MatchStatusScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E7C9),
                  border: Border.all(color: const Color(0xFFE5C88B), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'WAITING',
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFFDCAE5A),
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEBE6D8),
                          ),
                        ),
                        RotationTransition(
                          turns: _radarController,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.transparent,
                                  const Color(0xFFDCAE5A).withOpacity(0.0),
                                  const Color(0xFFDCAE5A).withOpacity(0.4),
                                ],
                                stops: const [0.0, 0.7, 0.95, 1.0],
                                transform: const GradientRotation(math.pi / 2),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const CircleAvatar(
                            radius: 48,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Waiting for Sarah',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "We'll let you know as soon as she accepts.",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              Text(
                'SATURDAY 5:00 PM',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              // MOCK BACKEND RESULT: Simulate the other person accepting
              TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ref
                      .read(matchRepositoryProvider.notifier)
                      .accept(widget.matchId);
                  context.pushReplacement(
                      AppRoutes.matchConfirmedPath(widget.matchId));
                },
                child: Text(
                  '[DEV] Simulate Other Accepted',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.pop();
                },
                child: Text(
                  'Cancel request',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB54C4C),
                    fontWeight: FontWeight.w600,
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
