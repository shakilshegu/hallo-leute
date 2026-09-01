import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/state/safety_controller.dart';

const _ink = Color(0xFF1D3D33);

/// Account-level list of people the user has blocked, with unblock.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  final Set<String> _working = {};

  Future<void> _unblock(BlockedUser user) async {
    if (_working.contains(user.id)) return;
    setState(() => _working.add(user.id));
    try {
      await ref.read(safetyApiProvider).unblockUser(user.id);
      ref.invalidate(blockedUsersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} unblocked.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(safetyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _working.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final blocked = ref.watch(blockedUsersProvider);

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
          'Blocked users',
          style: textTheme.titleMedium
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: blocked.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _ink)),
          error: (e, _) => _message(
            context,
            safetyErrorMessage(e),
            onRetry: () => ref.invalidate(blockedUsersProvider),
          ),
          data: (users) {
            if (users.isEmpty) {
              return _message(
                context,
                "You haven't blocked anyone.",
              );
            }
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(blockedUsersProvider.future),
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: _ink.withOpacity(0.05),
                ),
                itemBuilder: (context, i) {
                  final u = users[i];
                  final busy = _working.contains(u.id);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFE6EBE6),
                          backgroundImage: (u.profileImage != null &&
                                  u.profileImage!.isNotEmpty)
                              ? NetworkImage(u.profileImage!)
                              : null,
                          child: (u.profileImage == null ||
                                  u.profileImage!.isEmpty)
                              ? const Icon(Icons.person, size: 20, color: _ink)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            u.name,
                            style: textTheme.titleMedium?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  _unblock(u);
                                },
                          child: busy
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Unblock'),
                        ),
                      ],
                    ),
                  );
                },
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
