import 'package:flutter/material.dart';

/// PREMIUM MODERN homepage concept — clean, minimal, editorial.
/// XP / streak / achievements are present but deliberately quiet;
/// the emphasis is on typography, whitespace and elegant cards.
class PremiumHomeScreen extends StatelessWidget {
  const PremiumHomeScreen({super.key});

  static const _ink = Color(0xFF17181A);
  static const _muted = Color(0xFF8A8F98);
  static const _bg = Color(0xFFFAFAFA);
  static const _accent = Color(0xFF4C4FE0);
  static const _accentSoft = Color(0xFFEEEEFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: const [
            _TopBar(),
            SizedBox(height: 28),
            _DailyGoalCard(),
            SizedBox(height: 32),
            _SectionHeader(title: 'Continue Learning'),
            SizedBox(height: 14),
            _ContinueLessonCard(
              subject: 'Travel German',
              lesson: 'Lesson 4 · Asking for Directions',
              progress: 0.72,
              icon: Icons.map_outlined,
            ),
            SizedBox(height: 12),
            _ContinueLessonCard(
              subject: 'Grammar Basics',
              lesson: 'Lesson 2 · Verb Conjugation',
              progress: 0.35,
              icon: Icons.menu_book_outlined,
            ),
            SizedBox(height: 32),
            _SectionHeader(title: 'Recommended for You'),
            SizedBox(height: 14),
            _RecommendedRow(),
            SizedBox(height: 32),
            _SectionHeader(title: 'Learning Progress'),
            SizedBox(height: 14),
            _ProgressStatsRow(),
            SizedBox(height: 32),
            _SectionHeader(title: 'Recent Lessons'),
            SizedBox(height: 8),
            _RecentLessonsList(),
            SizedBox(height: 32),
            _SectionHeader(title: 'Achievements'),
            SizedBox(height: 14),
            _AchievementsStrip(),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: PremiumHomeScreen._accentSoft,
          child: Text(
            'P',
            style: TextStyle(
              color: PremiumHomeScreen._accent,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(fontSize: 13, color: PremiumHomeScreen._muted),
              ),
              SizedBox(height: 2),
              Text(
                'Priya Mehaboob',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PremiumHomeScreen._ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        const _QuietStatChip(icon: Icons.local_fire_department_rounded, label: '12'),
        const SizedBox(width: 8),
        const _QuietStatChip(icon: Icons.bolt_rounded, label: 'Lv 6'),
      ],
    );
  }
}

class _QuietStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuietStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: PremiumHomeScreen._muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: PremiumHomeScreen._ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard();

  @override
  Widget build(BuildContext context) {
    const progress = 0.6;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 5,
                    backgroundColor: const Color(0xFFEFEFF3),
                    valueColor: const AlwaysStoppedAnimation<Color>(PremiumHomeScreen._accent),
                  ),
                ),
                const Text(
                  '60%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: PremiumHomeScreen._ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Goal',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: PremiumHomeScreen._ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '12 of 20 XP today · 6 min left',
                  style: TextStyle(fontSize: 12.5, color: PremiumHomeScreen._muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: PremiumHomeScreen._ink,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ContinueLessonCard extends StatelessWidget {
  final String subject;
  final String lesson;
  final double progress;
  final IconData icon;

  const _ContinueLessonCard({
    required this.subject,
    required this.lesson,
    required this.progress,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: PremiumHomeScreen._accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: PremiumHomeScreen._accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: PremiumHomeScreen._ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson,
                  style: const TextStyle(fontSize: 12, color: PremiumHomeScreen._muted),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0xFFEFEFF3),
                    valueColor: const AlwaysStoppedAnimation<Color>(PremiumHomeScreen._accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: PremiumHomeScreen._muted),
        ],
      ),
    );
  }
}

class _RecommendedRow extends StatelessWidget {
  const _RecommendedRow();

  static const _items = [
    (title: 'Everyday Phrases', level: 'Beginner', icon: Icons.chat_bubble_outline_rounded),
    (title: 'Numbers & Counting', level: 'Beginner', icon: Icons.pin_outlined),
    (title: 'Food & Dining', level: 'Intermediate', icon: Icons.restaurant_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            width: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0F0F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: PremiumHomeScreen._accent, size: 22),
                const Spacer(),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: PremiumHomeScreen._ink,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: PremiumHomeScreen._accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.level,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: PremiumHomeScreen._accent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressStatsRow extends StatelessWidget {
  const _ProgressStatsRow();

  static const _stats = [
    (label: 'Lessons Done', value: '42'),
    (label: 'Words Learned', value: '318'),
    (label: 'Current Level', value: '6'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < _stats.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == _stats.length - 1 ? 0 : 10),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                children: [
                  Text(
                    _stats[i].value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: PremiumHomeScreen._ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _stats[i].label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10.5, color: PremiumHomeScreen._muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentLessonsList extends StatelessWidget {
  const _RecentLessonsList();

  static const _lessons = [
    (title: 'Greetings & Introductions', meta: 'Completed · 8 XP', icon: Icons.check_circle_rounded, done: true),
    (title: 'Colors & Shapes', meta: 'Completed · 6 XP', icon: Icons.check_circle_rounded, done: true),
    (title: 'Family Members', meta: 'In progress', icon: Icons.play_circle_outline_rounded, done: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _lessons
          .map(
            (lesson) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(
                    lesson.icon,
                    size: 20,
                    color: lesson.done ? const Color(0xFF34C759) : PremiumHomeScreen._accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lesson.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: PremiumHomeScreen._ink,
                      ),
                    ),
                  ),
                  Text(
                    lesson.meta,
                    style: const TextStyle(fontSize: 11.5, color: PremiumHomeScreen._muted),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AchievementsStrip extends StatelessWidget {
  const _AchievementsStrip();

  static const _badges = [
    (icon: Icons.local_fire_department_rounded, label: '12-day streak'),
    (icon: Icons.military_tech_rounded, label: 'First quiz'),
    (icon: Icons.workspace_premium_rounded, label: 'Vocab master'),
    (icon: Icons.emoji_events_rounded, label: '40 lessons'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _badges
          .map(
            (badge) => Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: PremiumHomeScreen._accentSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badge.icon, size: 18, color: PremiumHomeScreen._accent),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    badge.label,
                    style: const TextStyle(fontSize: 9.5, color: PremiumHomeScreen._muted),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
