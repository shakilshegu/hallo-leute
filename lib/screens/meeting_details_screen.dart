import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/meeting_controller.dart';

const _weekdayNames = [
  'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', //
];
const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatMeetingTime(DateTime time) {
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
    final meeting = ref.watch(meetingProvider(meetingId));
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
      ),
      body: SafeArea(
        child: ListView(
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
                      const CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(
                          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meeting.partnerName,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              meeting.hasEnded ? 'Meeting ended' : 'Upcoming',
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
                  _detailRow(context, 'WHEN', _formatMeetingTime(meeting.startTime)),
                  const SizedBox(height: 16),
                  _detailRow(
                      context, 'WHERE', meeting.cafeName ?? 'Not agreed yet'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _actionRow(
              context,
              icon: Icons.chat_bubble_outline,
              label: 'Message',
              onTap: () => context.push(AppRoutes.chatPath(meetingId)),
            ),
            _actionRow(
              context,
              icon: Icons.shield_outlined,
              label: 'Safety center',
              onTap: () => context.push(AppRoutes.safetyPath(meetingId)),
            ),
            if (meeting.hasEnded && !meeting.feedbackSubmitted)
              _actionRow(
                context,
                icon: Icons.rate_review_outlined,
                label: 'Leave feedback',
                onTap: () => context.push(AppRoutes.feedbackPath(meetingId)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
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
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary.withOpacity(0.7)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: colorScheme.primary.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}
