import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/connection_controller.dart';

const _ink = Color(0xFF1D3D33);

/// The people the current user made a mutual connection with (`GET /connections`).
class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final connections = ref.watch(connectionsProvider);

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
          'Connections',
          style: textTheme.titleMedium
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: connections.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _ink)),
          error: (e, _) => _message(
            context,
            connectionErrorMessage(e),
            onRetry: () => ref.invalidate(connectionsProvider),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return _message(context, 'No connections yet.');
            }
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(connectionsProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: rows.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: _ink.withOpacity(0.05)),
                itemBuilder: (context, i) => _ConnectionTile(rows[i]),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String text, {VoidCallback? onRetry}) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style:
                  textTheme.titleMedium?.copyWith(color: _ink.withOpacity(0.7)),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionTile extends StatelessWidget {
  const _ConnectionTile(this.connection);

  final Connection connection;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = connection.user;
    final hasImage = user.profileImage != null && user.profileImage!.isNotEmpty;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.connectionDetailPath(connection.id));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE6EBE6),
              backgroundImage:
                  hasImage ? NetworkImage(user.profileImage!) : null,
              child: hasImage
                  ? null
                  : const Icon(Icons.person, color: _ink, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (user.averageRating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: Color(0xFFE6A316)),
                        const SizedBox(width: 4),
                        Text(
                          user.averageRating!.toStringAsFixed(1),
                          style: textTheme.bodySmall
                              ?.copyWith(color: _ink.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _ink.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
