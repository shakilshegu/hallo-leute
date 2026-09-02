import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';

const _bg = Color(0xFFF8F9F8);
const _ink = Color(0xFF1B3B2B);

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', //
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

class MeetingsScreen extends ConsumerStatefulWidget {
  const MeetingsScreen({super.key});

  @override
  ConsumerState<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends ConsumerState<MeetingsScreen> {
  int _tab = 0; // 0 = Upcoming, 1 = Past

  bool _isUpcoming(MeetingDetails m) {
    if (m.status != MeetingLifecycle.confirmed) return false;
    final ends = m.endsAt;
    return ends == null || ends.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meetings = ref.watch(allMeetingsProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Meetings',
          style: textTheme.titleMedium
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                _tabHeader(
                    'UPCOMING', _tab == 0, () => setState(() => _tab = 0)),
                const SizedBox(width: 24),
                _tabHeader('PAST', _tab == 1, () => setState(() => _tab = 1)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: meetings.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: _ink)),
              error: (e, _) => _message(
                cafeErrorMessage(e),
                onRetry: () => ref.invalidate(allMeetingsProvider),
              ),
              data: (all) {
                final list = all
                    .where(
                      _tab == 0 ? _isUpcoming : (m) => !_isUpcoming(m),
                    )
                    .toList();
                if (list.isEmpty) {
                  return _message(
                    _tab == 0
                        ? 'No coffee planned yet'
                        : "No past meetings yet",
                    subtitle: _tab == 0
                        ? "Pick a time and we'll find someone."
                        : null,
                  );
                }
                return RefreshIndicator(
                  color: _ink,
                  onRefresh: () async =>
                      ref.refresh(allMeetingsProvider.future),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _MeetingCard(meeting: list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabHeader(String label, bool selected, VoidCallback onTap) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: selected ? _ink : _ink.withOpacity(0.4),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: label.length * 7.0,
            color: selected ? _ink : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _message(String title, {String? subtitle, VoidCallback? onRetry}) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      // ListView so pull-to-refresh still works on the error state
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EBE6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_outlined, color: _ink, size: 30),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium
              ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: _ink.withOpacity(0.6)),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MeetingCard extends StatelessWidget {
  const _MeetingCard({required this.meeting});

  final MeetingDetails meeting;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final start = meeting.startsAt;
    final when = start == null
        ? '${meeting.date} · ${meeting.startTime}'
        : '${_weekdays[start.weekday - 1]} '
            '${_months[start.month - 1]} ${start.day} · '
            '${_clock(start)}';
    final img = meeting.partner.profileImage;
    final hasImg = img != null && img.isNotEmpty;

    final ended = meeting.endsAt?.isBefore(DateTime.now()) ?? false;
    final (badge, badgeColor) = switch (meeting.status) {
      MeetingLifecycle.confirmed when ended => (
          'AWAITING FEEDBACK',
          const Color(0xFFB07A00)
        ),
      MeetingLifecycle.confirmed => ('CONFIRMED', const Color(0xFF2E7D32)),
      MeetingLifecycle.completed => ('COMPLETED', _ink.withOpacity(0.5)),
      MeetingLifecycle.cancelled => ('CANCELLED', const Color(0xFFB03A2E)),
      _ => ('', Colors.transparent),
    };

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.meetingPath(meeting.id));
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$when  ·  ${meeting.durationMinutes} MIN',
                    style: textTheme.labelSmall?.copyWith(
                      color: _ink.withOpacity(0.5),
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (badge.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: textTheme.labelSmall?.copyWith(
                        color: badgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              meeting.cafe.name,
              style: textTheme.titleMedium
                  ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _ink.withOpacity(0.08),
                  backgroundImage: hasImg ? NetworkImage(img) : null,
                  child: hasImg
                      ? null
                      : const Icon(Icons.person, color: _ink, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'with ${meeting.partner.name}',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: _ink.withOpacity(0.8)),
                  ),
                ),
                Icon(Icons.chevron_right, color: _ink.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }
}
