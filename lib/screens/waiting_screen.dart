import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/match_controller.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/widgets/match_slot_format.dart';

/// "Waiting for the other person to accept". Polls `GET /matches/:id` and
/// moves on the moment the backend reports the match confirmed (both accepted)
/// or gone (declined / expired). No dev simulation.
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

  Timer? _poll;
  bool _left = false;
  MatchDetails? _match;

  @override
  void initState() {
    super.initState();
    _fetch();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _fetch());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    if (_left) return;
    try {
      final match =
          await ref.read(matchingApiProvider).getMatch(widget.matchId);
      if (!mounted || _left) return;
      ref
          .read(matchRepositoryProvider.notifier)
          .upsert(matchFromDetails(match));
      setState(() => _match = match);

      if (match.isConfirmed) {
        _left = true;
        _poll?.cancel();
        HapticFeedback.heavyImpact();
        context.pushReplacement(AppRoutes.matchConfirmedPath(widget.matchId));
      } else if (match.isTerminal) {
        _leaveWith(
          match.isExpired
              ? 'Sorry, this match has expired.'
              : '${match.user.name} passed on this match.',
        );
      }
    } catch (e) {
      if (!mounted || _left) return;
      if (e is Exception) {
        final message = matchingErrorMessage(e);
        // A 404 means the match is gone — leave. Network blips: keep polling.
        if (message == 'Match no longer exists.') {
          _leaveWith(message);
        }
      }
    }
  }

  void _leaveWith(String message) {
    if (_left) return;
    _left = true;
    _poll?.cancel();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final match = _match;
    final partnerName = match?.user.name ?? 'them';
    final photoUrl = match?.user.photoUrl;

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
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFFDDE5DE),
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? const Icon(Icons.person,
                                    size: 40, color: Color(0xFF1B3B2B))
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Waiting for $partnerName',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "We'll let you know as soon as they accept.",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              if (match != null)
                Text(
                  formatMatchSlot(match).toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              const Spacer(flex: 3),
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _left = true;
                  _poll?.cancel();
                  context.go(AppRoutes.home);
                },
                child: Text(
                  'Back to home',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary.withOpacity(0.7),
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
