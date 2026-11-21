import 'package:flutter/material.dart';

import '../../app_info.dart';
import '../../data/auth/auth_service.dart';
import '../../data/progress.dart';
import '../../data/remote/feedback_remote.dart';
import '../../data/vocabulary.dart';
import '../../shared/widgets/reveal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../onboarding/onboarding_data.dart';
import '../../services/reminders.dart';
import '../share/share_progress.dart';
import '../home/home_content.dart';
import 'account_card.dart';
import 'feedback_card.dart';
import 'edit_profile_sheet.dart';
import 'reminder_card.dart';

/// Who's learning and what their plan is.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile});

  final OnboardingData profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.name.trim();
    final level = profile.level;
    final goals = LearningGoal.values
        .where(profile.goals.contains)
        .map((g) => g.label)
        .join(', ');
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final progress = ProgressScope.of(context);
    final auth = AuthScope.maybeOf(context);
    final reminders = RemindersScope.maybeOf(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
      children: [
        StaggeredColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Profile', style: AppText.display(28, color: AppColors.cream)),
            const SizedBox(height: 28),
            Center(
              child: Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cream,
                  border: Border.all(
                    color: AppColors.mustard.withValues(alpha: 0.6),
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: AppText.display(36, color: AppColors.navy),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name.isEmpty ? 'Learner' : name,
              textAlign: TextAlign.center,
              style: AppText.display(24, color: AppColors.cream),
            ),
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mustard.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  level == null
                      ? 'Level not set'
                      : '${level.code} · ${level.title}',
                  style: AppText.body(
                    13,
                    weight: FontWeight.w800,
                    color: AppColors.mustard,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton.icon(
                onPressed: () => showEditProfile(context, profile),
                icon: const Icon(Icons.edit_outlined, size: 17),
                label: const Text('Edit profile'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.creamMuted,
                  textStyle: AppText.body(13.5, weight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '${progress.totalLearned}',
                    label: 'Learned',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    value: '${progress.totalMastered}',
                    label: 'Mastered',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    value: '${progress.streak}',
                    label: 'Day streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => showShareProgress(context),
                icon: const Icon(Icons.ios_share_rounded, size: 19),
                label: const Text('Share my progress'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cream,
                  side: BorderSide(
                    color: AppColors.cream.withValues(alpha: 0.22),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: AppText.body(15, weight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (auth != null) ...[
              AccountCard(auth: auth),
              const SizedBox(height: 16),
            ],
            if (reminders != null) ...[
              ReminderCard(reminders: reminders),
              const SizedBox(height: 12),
              PopupsCard(reminders: reminders, wordsFor: wordsForDay),
              const SizedBox(height: 16),
            ],
            if (auth != null) ...[
              FeedbackCard(
                remote: SupabaseFeedbackRemote(
                  auth.client,
                  ensureSession: auth.ensureGuest,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _InfoCard(
              rows: [
                (
                  Icons.local_fire_department_outlined,
                  'Daily goal',
                  '${profile.dailyGoal.words} words a day',
                ),
                (
                  Icons.flag_outlined,
                  'Learning for',
                  goals.isEmpty ? '—' : goals,
                ),
                (
                  Icons.replay_rounded,
                  'Due for review',
                  '${progress.dueCount} words',
                ),
                (
                  Icons.menu_book_outlined,
                  'Still to discover',
                  '${vocabulary.length - progress.totalLearned} words',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _Credits(),
            const SizedBox(height: 28),
            Text(
              'Hallo Leute · v${AppInfo.version}',
              textAlign: TextAlign.center,
              style: AppText.body(12.5, color: AppColors.creamMuted),
            ),
            const SizedBox(height: 2),
            Text(
              'Nur positiv',
              textAlign: TextAlign.center,
              style: AppText.body(
                12.5,
                weight: FontWeight.w700,
                color: AppColors.mustard,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.display(24, color: AppColors.cream)),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppText.body(12, color: AppColors.creamMuted, height: 1.25),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(IconData, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.navyLine.withValues(alpha: 0.45),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 20, color: AppColors.mustard),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: Text(
                      rows[i].$2,
                      style: AppText.body(14, color: AppColors.creamMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 6,
                    child: Text(
                      rows[i].$3,
                      textAlign: TextAlign.right,
                      style: AppText.body(
                        14,
                        weight: FontWeight.w800,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Attribution required by the open datasets behind the word list.
class _Credits extends StatelessWidget {
  const _Credits();

  @override
  Widget build(BuildContext context) {
    final sources = Vocabulary.instance.sources.values.toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORD DATA',
            style: AppText.body(
              11.5,
              weight: FontWeight.w800,
              color: AppColors.creamMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          for (final s in sources)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                s,
                style: AppText.body(
                  12.5,
                  color: AppColors.creamMuted,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
