import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/calendar_launcher.dart';
import 'package:poppylo/services/chat_api.dart' show chatApiProvider;
import 'package:poppylo/services/maps_launcher.dart';
import 'package:poppylo/state/cafe_controller.dart'
    show
        allMeetingsProvider,
        cafeErrorMessage,
        meetingDetailsProvider,
        upcomingMeetingsProvider;
import 'package:poppylo/state/feedback_controller.dart';
import 'package:poppylo/widgets/cancel_meeting_sheet.dart';

String _formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hrs = minutes ~/ 60;
  final rem = minutes % 60;
  final hLabel = '$hrs hr';
  return rem == 0 ? hLabel : '$hLabel $rem min';
}

const _weekdayNames = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Local "I've arrived" latch, keyed by meeting id (resets on app restart).
final _arrivedProvider = StateProvider.family<bool, String>((ref, _) => false);

String _formatMeetingTime(DateTime? time) {
  if (time == null) return 'Time to be confirmed';
  final weekday = _weekdayNames[time.weekday - 1];
  final month = _monthNames[time.month - 1];
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour < 12 ? 'AM' : 'PM';
  return '$weekday, $month ${time.day} · $hour12:$minute $period';
}

class MeetingDetailsScreen extends ConsumerWidget {
  final String meetingId;
  const MeetingDetailsScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingAsync = ref.watch(meetingDetailsProvider(meetingId));
    // The backend is the source of truth for feedback eligibility.
    final feedbackStatus =
        ref.watch(feedbackStatusProvider(meetingId)).valueOrNull;
    final canLeaveFeedback = feedbackStatus?.canSubmit ?? false;
    final feedbackSubmitted = feedbackStatus?.submitted ?? false;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Meeting details',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shield_outlined, color: colorScheme.primary),
            tooltip: 'Safety Center',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.safetyPath(meetingId));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: meetingAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorView(
            message: cafeErrorMessage(e),
            onRetry: () => ref.invalidate(meetingDetailsProvider(meetingId)),
          ),
          data: (meeting) => _loaded(
            context,
            ref,
            meeting,
            canLeaveFeedback: canLeaveFeedback,
            feedbackSubmitted: feedbackSubmitted,
          ),
        ),
      ),
    );
  }

  Widget _loaded(
    BuildContext context,
    WidgetRef ref,
    MeetingDetails meeting, {
    required bool canLeaveFeedback,
    required bool feedbackSubmitted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final ended = meeting.endsAt?.isBefore(DateTime.now()) ?? false;
    final isCancelled = meeting.status == MeetingLifecycle.cancelled;
    final isCompleted =
        meeting.status == MeetingLifecycle.completed || (ended && !isCancelled);
    final canCancel = meeting.status == MeetingLifecycle.confirmed && !ended;

    final statusLabel = isCancelled
        ? 'Meeting cancelled'
        : isCompleted
            ? 'Meeting ended'
            : 'Upcoming';

    final img = meeting.partner.profileImage;
    final hasImg = img != null && img.isNotEmpty;
    final address = meeting.cafe.address;
    final arrived = ref.watch(_arrivedProvider(meeting.id));
    final canCheckIn = meeting.status == MeetingLifecycle.confirmed && !ended;
    final showFeedbackPrompt =
        (isCompleted || canLeaveFeedback || feedbackSubmitted) && !isCancelled;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.primary.withOpacity(0.08),
                    backgroundImage: hasImg ? NetworkImage(img) : null,
                    child: hasImg
                        ? null
                        : Icon(Icons.person, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meeting.partner.name,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          statusLabel,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _detailRow(context, 'WHEN', _formatMeetingTime(meeting.startsAt)),
              const SizedBox(height: 16),
              _detailRow(context, 'DURATION',
                  _formatDuration(meeting.durationMinutes)),
              const SizedBox(height: 16),
              _detailRow(context, 'CAFÉ', meeting.cafe.name),
              if (address.isNotEmpty) ...[
                const SizedBox(height: 16),
                _detailRow(context, 'ADDRESS', address),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Map preview — tap to open directions
        GestureDetector(
          onTap: () => _openDirections(context, meeting.cafe),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Colors.white.withOpacity(0.5),
                  colorBlendMode: BlendMode.screen,
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined,
                          size: 16, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Open in Maps',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (showFeedbackPrompt) ...[
          _FeedbackBanner(
            submitted: feedbackSubmitted,
            canSubmit: canLeaveFeedback,
            partnerName: meeting.partner.name,
            onTap: canLeaveFeedback
                ? () => context.push(AppRoutes.feedbackPath(meetingId))
                : null,
          ),
          const SizedBox(height: 8),
        ],
        _actionRow(
          context,
          icon: Icons.directions_outlined,
          label: 'Get directions',
          onTap: () => _openDirections(context, meeting.cafe),
        ),
        if (!showFeedbackPrompt)
          _actionRow(
            context,
            icon: Icons.event_available_outlined,
            label: 'Add to calendar',
            onTap: () => _addToCalendar(context, meeting),
          ),
        _actionRow(
          context,
          icon: Icons.chat_bubble_outline,
          label: 'Message ${meeting.partner.name}',
          onTap: () => context.push(AppRoutes.chatPath(meetingId)),
        ),
        if (canCheckIn)
          _actionRow(
            context,
            icon: arrived ? Icons.check_circle : Icons.check_circle_outline,
            label: arrived ? "You've checked in" : "I've arrived",
            enabled: !arrived,
            onTap: () => _markArrived(context, ref, meeting),
          ),
        if (canCancel)
          _actionRow(
            context,
            icon: Icons.cancel_outlined,
            label: 'Cancel meeting',
            isDestructive: true,
            onTap: () async {
              final cancelled = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => CancelMeetingSheet(
                  meetingId: meetingId,
                  partnerName: meeting.partner.name,
                ),
              );
              if (cancelled == true && context.mounted) {
                ref.invalidate(upcomingMeetingsProvider);
                ref.invalidate(allMeetingsProvider);
                ref.invalidate(meetingDetailsProvider(meetingId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coffee Meet cancelled.')),
                );
                context.go(AppRoutes.home);
              }
            },
          ),
      ],
    );
  }

  Future<void> _openDirections(BuildContext context, CoffeeShop cafe) async {
    HapticFeedback.lightImpact();
    final ok = await openCafeInMaps(
      latitude: cafe.latitude,
      longitude: cafe.longitude,
      name: cafe.name,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open Maps on this device.")),
      );
    }
  }

  Future<void> _addToCalendar(
    BuildContext context,
    MeetingDetails meeting,
  ) async {
    HapticFeedback.lightImpact();
    final start = meeting.startsAt;
    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This meeting has no confirmed time yet.')),
      );
      return;
    }
    final ok = await addMeetingToCalendar(
      title: 'Coffee with ${meeting.partner.name}',
      start: start,
      durationMinutes: meeting.durationMinutes,
      location: meeting.cafe.address.isNotEmpty
          ? '${meeting.cafe.name}, ${meeting.cafe.address}'
          : meeting.cafe.name,
      details: 'Coffee Meet at ${meeting.cafe.name}.',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open your calendar app.")),
      );
    }
  }

  Future<void> _markArrived(
    BuildContext context,
    WidgetRef ref,
    MeetingDetails meeting,
  ) async {
    if (ref.read(_arrivedProvider(meeting.id))) return;
    HapticFeedback.heavyImpact();
    ref.read(_arrivedProvider(meeting.id).notifier).state = true;
    try {
      await ref
          .read(chatApiProvider)
          .sendMessage(meeting.matchId, "I've arrived 👋");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("We let ${meeting.partner.name} know you're here."),
          ),
        );
      }
    } catch (_) {
      ref.read(_arrivedProvider(meeting.id).notifier).state = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't send that — please retry.")),
        );
      }
    }
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool enabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final base = isDestructive ? const Color(0xFFA5392B) : colorScheme.primary;
    final color = enabled ? base : base.withOpacity(0.4);
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap();
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (enabled)
              Icon(Icons.chevron_right, color: color.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.submitted,
    required this.canSubmit,
    required this.partnerName,
    this.onTap,
  });

  final bool submitted;
  final bool canSubmit;
  final String partnerName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final (icon, title, subtitle) = submitted
        ? (
            Icons.check_circle,
            'Thanks for your feedback',
            "We'll let you know if $partnerName wants to meet again.",
          )
        : canSubmit
            ? (
                Icons.rate_review_outlined,
                'How was your coffee with $partnerName?',
                'Leave feedback — it stays private.',
              )
            : (
                Icons.hourglass_empty,
                'Feedback closed',
                'This meeting can no longer be reviewed.',
              );

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap!();
            },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: submitted
              ? colorScheme.primary.withOpacity(0.06)
              : const Color(0xFF2B4739),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: submitted ? colorScheme.primary : Colors.white,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: submitted ? colorScheme.primary : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: (submitted ? colorScheme.primary : Colors.white)
                          .withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: submitted ? colorScheme.primary : Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: colorScheme.primary.withOpacity(0.4), size: 40),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.primary.withOpacity(0.8)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
