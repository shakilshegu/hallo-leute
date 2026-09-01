import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/chat_controller.dart';

const _ink = Color(0xFF1D3D33);
const _bg = Color(0xFFF3F1EB);

/// The "Chats" bottom-nav destination — the caller's confirmed-match
/// conversations (`GET /chats`). Same visual language as before, real data.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final chatsAsync = ref.watch(chatListProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(chatListProvider.future),
          child: chatsAsync.when(
            loading: () => const _Fill(
              child: Center(child: CircularProgressIndicator(color: _ink)),
            ),
            error: (e, _) => _Fill(
              child: _Message(
                title: chatErrorMessage(e),
                onRetry: () => ref.invalidate(chatListProvider),
              ),
            ),
            data: (chats) {
              if (chats.isEmpty) {
                return const _Fill(
                  child: _Message(
                    title: 'No conversations yet',
                    subtitle: 'Once a match is confirmed you can message each '
                        'other here.',
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 16.0),
                itemCount: chats.length + 1,
                separatorBuilder: (_, i) => i == 0
                    ? const SizedBox(height: 8)
                    : Divider(
                        height: 1,
                        thickness: 1,
                        color: _ink.withOpacity(0.05),
                      ),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Text(
                      'MESSAGES • ${chats.length}',
                      style: textTheme.labelSmall?.copyWith(
                        color: _ink.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    );
                  }
                  return _ChatRow(summary: chats[i - 1]);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.summary});
  final ChatSummary summary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photo = summary.participant.profileImage;
    final unread = summary.unreadCount > 0;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.chatByMatchPath(summary.matchId));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE6EBE6),
              backgroundImage: (photo != null && photo.isNotEmpty)
                  ? NetworkImage(photo)
                  : null,
              child: (photo == null || photo.isEmpty)
                  ? const Icon(Icons.person, size: 20, color: _ink)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.participant.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary.lastMessage ?? 'Say hello ☕',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: _ink.withOpacity(unread ? 0.9 : 0.5),
                      fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (summary.lastMessageAt != null)
                  Text(
                    formatChatTime(summary.lastMessageAt!),
                    style: textTheme.labelSmall?.copyWith(
                      color: _ink.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                const SizedBox(height: 6),
                if (unread)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: const BoxDecoration(
                      color: _ink,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      '${summary.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fill extends StatelessWidget {
  const _Fill({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
              height: MediaQuery.of(context).size.height * 0.7, child: child)
        ],
      );
}

class _Message extends StatelessWidget {
  const _Message({required this.title, this.subtitle, this.onRetry});
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: _ink.withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: _ink.withOpacity(0.5), height: 1.4),
              ),
            ],
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
