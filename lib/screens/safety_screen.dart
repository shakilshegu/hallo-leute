import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart' show MeetingDetails;
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart'
    show meetingDetailsProvider, upcomingMeetingsProvider;
import 'package:poppylo/state/chat_controller.dart'
    show chatControllerProvider, chatListProvider;
import 'package:poppylo/state/safety_controller.dart';
import 'package:poppylo/widgets/cancel_meeting_sheet.dart';

/// Full-page safety center for a specific meeting.
class SafetyScreen extends ConsumerStatefulWidget {
  final String meetingId;
  const SafetyScreen({super.key, required this.meetingId});

  @override
  ConsumerState<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends ConsumerState<SafetyScreen> {
  bool _blocking = false;

  MeetingDetails? get _meeting =>
      ref.read(meetingDetailsProvider(widget.meetingId)).valueOrNull;

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  Future<void> _blockUser(String userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Block $name?'),
        content: Text(
          "$name won't be able to match or message you again. "
          'This conversation will close.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFD32F2F)),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true || _blocking) return;

    setState(() => _blocking = true);
    try {
      await ref.read(safetyApiProvider).blockUser(userId);
      final matchId = _meeting?.matchId;
      if (matchId != null) {
        ref.invalidate(chatControllerProvider(matchId));
      }
      ref.invalidate(chatListProvider);
      ref.invalidate(blockedUsersProvider);
      if (!mounted) return;
      _snack('$name blocked.');
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _blocking = false);
      _snack(safetyErrorMessage(e));
    }
  }

  Future<void> _cancelMeeting() async {
    final name = _meeting?.partner.name ?? 'your match';
    HapticFeedback.mediumImpact();
    final cancelled = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CancelMeetingSheet(
        meetingId: widget.meetingId,
        partnerName: name,
      ),
    );
    if (cancelled == true && mounted) {
      ref.invalidate(upcomingMeetingsProvider);
      ref.invalidate(meetingDetailsProvider(widget.meetingId));
      final matchId = _meeting?.matchId;
      if (matchId != null) ref.invalidate(chatControllerProvider(matchId));
      _snack('Coffee Meet cancelled.');
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final meeting = ref.watch(meetingDetailsProvider(widget.meetingId));
    final partner = meeting.valueOrNull?.partner;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Safety Center',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Meet safely',
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A few things that keep this good for everyone.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            _buildTipCard(context,
                icon: Icons.store_outlined, title: 'Meet in a public place'),
            const SizedBox(height: 12),
            _buildTipCard(context,
                icon: Icons.lock_outline,
                title: 'Keep personal details private'),
            const SizedBox(height: 12),
            _buildTipCard(context,
                icon: Icons.location_on_outlined,
                title: "Tell someone where you're going"),
            const SizedBox(height: 12),
            _buildTipCard(context,
                icon: Icons.exit_to_app, title: 'You can leave at any time'),
            const SizedBox(height: 32),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 24),
            Text(
              'SECONDARY ACTIONS',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildDangerButton(
              context: context,
              icon: Icons.report_problem_outlined,
              label: 'Report user',
              onPressed: partner == null
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.reportPath(partner.id));
                    },
            ),
            const SizedBox(height: 12),
            _buildDangerButton(
              context: context,
              icon: Icons.block,
              label: _blocking ? 'Blocking…' : 'Block user',
              onPressed: (partner == null || _blocking)
                  ? null
                  : () => _blockUser(partner.id, partner.name),
            ),
            const SizedBox(height: 12),
            _buildDangerButton(
              context: context,
              icon: Icons.cancel_outlined,
              label: 'Cancel meeting',
              onPressed: _cancelMeeting,
              isLight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(BuildContext context,
      {required IconData icon, required String title}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE6EBE6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isLight = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        label: Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: const Color(0xFFD32F2F),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLight ? const Color(0xFFEBEBEB) : const Color(0xFFFFEBEE),
          disabledBackgroundColor:
              isLight ? const Color(0xFFEBEBEB) : const Color(0xFFFFEBEE),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
