import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/connection_controller.dart';

const _ink = Color(0xFF1D3D33);

/// One mutual connection's public profile (`GET /connections/:id`). Also the
/// target of "View profile" on the Mutual Connection screen. Public fields
/// only — no ratings breakdown, no feedback.
class ConnectionDetailScreen extends ConsumerWidget {
  final String connectionId;
  const ConnectionDetailScreen({super.key, required this.connectionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final detail = ref.watch(connectionDetailProvider(connectionId));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F1EB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: textTheme.titleMedium
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: detail.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _ink)),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    connectionErrorMessage(e),
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium
                        ?.copyWith(color: _ink.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(connectionDetailProvider(connectionId)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (connection) => _body(context, connection),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Connection connection) {
    final textTheme = Theme.of(context).textTheme;
    final user = connection.user;
    final hasImage = user.profileImage != null && user.profileImage!.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFE6EBE6),
            backgroundImage: hasImage ? NetworkImage(user.profileImage!) : null,
            child: hasImage
                ? null
                : const Icon(Icons.person, color: _ink, size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        if (user.job != null && user.job!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            user.job!,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: _ink.withOpacity(0.7)),
          ),
        ],
        if (user.averageRating != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, size: 18, color: Color(0xFFE6A316)),
              const SizedBox(width: 6),
              Text(
                user.averageRating!.toStringAsFixed(1),
                style: textTheme.titleSmall
                    ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              user.bio!,
              style: textTheme.bodyMedium?.copyWith(color: _ink, height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: 32),
        if (connection.meetingId != null)
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Reuse the existing chat for this meeting's match.
                context.push(AppRoutes.chatPath(connection.meetingId!));
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
                'Message',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
