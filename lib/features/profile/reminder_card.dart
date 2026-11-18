import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../services/reminders.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Turns reminders on (asking for notification permission) and tells the
/// learner what happened. Returns true when reminders are now on.
Future<bool> enableReminders(
  BuildContext context,
  Reminders reminders, {
  TimeOfDay? at,
}) async {
  final progress = ProgressScope.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final time = at ?? reminders.settings.time;
  final allowed = await reminders.requestPermission();
  if (!allowed) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Notifications are off for Poppylo. '
          'Turn them on in your phone settings.',
        ),
      ),
    );
    return false;
  }
  await reminders.update(
    reminders.settings.copyWith(
      enabled: true,
      hour: time.hour,
      minute: time.minute,
      offered: true,
    ),
    practisedToday: progress.practisedToday,
    streak: progress.streak,
  );
  if (context.mounted) {
    final label = MaterialLocalizations.of(context).formatTimeOfDay(time);
    messenger.showSnackBar(
      SnackBar(content: Text('Done! We\'ll remind you every day at $label.')),
    );
  }
  return true;
}

/// Profile card: daily reminder on/off and its time.
class ReminderCard extends StatelessWidget {
  const ReminderCard({super.key, required this.reminders});

  final Reminders reminders;

  Future<void> _pickTime(BuildContext context) async {
    final progress = ProgressScope.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: reminders.settings.time,
      helpText: 'Daily reminder time',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.mustard,
            onPrimary: AppColors.navy,
            surface: AppColors.navy800,
            onSurface: AppColors.cream,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    await reminders.update(
      reminders.settings.copyWith(hour: picked.hour, minute: picked.minute),
      practisedToday: progress.practisedToday,
      streak: progress.streak,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = reminders.settings;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(s.time);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: s.enabled ? () => _pickTime(context) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.mustard,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily reminder',
                        style: AppText.body(
                          15,
                          weight: FontWeight.w800,
                          color: AppColors.cream,
                        ),
                      ),
                      Text(
                        s.enabled
                            ? 'Every day at $time · tap to change'
                            : 'Off',
                        style: AppText.body(13, color: AppColors.creamMuted),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: s.enabled,
                  activeThumbColor: AppColors.navy,
                  activeTrackColor: AppColors.mustard,
                  inactiveThumbColor: AppColors.creamMuted,
                  inactiveTrackColor: AppColors.navy700,
                  onChanged: (on) async {
                    if (on) {
                      await enableReminders(context, reminders);
                    } else {
                      final progress = ProgressScope.of(context);
                      await reminders.update(
                        s.copyWith(enabled: false),
                        practisedToday: progress.practisedToday,
                        streak: progress.streak,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One-time offer shown after the first lesson.
class ReminderOffer extends StatelessWidget {
  const ReminderOffer({super.key, required this.reminders});

  final Reminders reminders;

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(reminders.settings.time);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mustard.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.mustard,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Make it a habit',
                  style: AppText.body(
                    15.5,
                    weight: FontWeight.w800,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A short daily reminder helps you keep your streak.',
            style: AppText.body(13.5, color: AppColors.creamMuted),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  final p = ProgressScope.of(context);
                  reminders.update(
                    reminders.settings.copyWith(offered: true),
                    practisedToday: p.practisedToday,
                    streak: p.streak,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.creamMuted,
                ),
                child: const Text('Not now'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: () => enableReminders(context, reminders),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.mustard,
                  foregroundColor: AppColors.navy,
                ),
                child: Text('Remind me at $time'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
