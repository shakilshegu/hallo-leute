import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/state/cafe_controller.dart' show meetingDetailsProvider;

class MutualConnectionScreen extends ConsumerWidget {
  final String meetingId;

  /// Passed via `GoRouter` `extra` when arriving from a feedback submission
  /// that formed a connection. Null when deep-linked without it — "View
  /// profile" is then unavailable, everything else still works.
  final String? connectionId;

  const MutualConnectionScreen({
    super.key,
    required this.meetingId,
    this.connectionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final partner =
        ref.watch(meetingDetailsProvider(meetingId)).valueOrNull?.partner;
    final partnerName = partner?.name ?? 'your match';
    final partnerImage = partner?.profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Warm beige
      body: Container(
        // Neon border effect
        decoration: BoxDecoration(
          border: Border.all(
            width: 4.0,
            color: Colors
                .transparent, // Handled by gradient wrapper or we can use a custom painter/gradient border.
          ),
        ),
        // A simple way to get gradient border is to wrap in a Container with padding
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF8A2BE2),
                Color(0xFF4169E1)
              ], // Purple to Royal Blue
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          padding: const EdgeInsets.all(4.0), // Border width
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F1EB),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    Text(
                      'You both enjoyed meeting.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looks like you made a connection.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Overlapping Avatars
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 - 80,
                            child: _avatar(
                              null,
                              fallbackIcon: Icons.person,
                              color: colorScheme.primary,
                            ),
                          ),
                          Positioned(
                            right: MediaQuery.of(context).size.width / 2 - 80,
                            child: _avatar(
                              partnerImage,
                              fallbackIcon: Icons.person_outline,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    Text(
                      'CONNECTION MADE • ${partnerName.toUpperCase()}',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          // Reuse the existing chat for this meeting's match —
                          // never creates a new one.
                          context.go(AppRoutes.chatPath(meetingId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF1B3B2B), // Dark green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Continue chat',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: connectionId == null
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              context.push(
                                AppRoutes.connectionDetailPath(connectionId!),
                              );
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'View profile',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _avatar(
    String? url, {
    required IconData fallbackIcon,
    required Color color,
  }) {
    final hasImage = url != null && url.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFFE6EBE6),
        backgroundImage: hasImage ? NetworkImage(url) : null,
        child: hasImage ? null : Icon(fallbackIcon, color: color, size: 36),
      ),
    );
  }
}
