import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/home_data.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/fun_icon.dart';

const _motions = [
  FunMotion.wobble,
  FunMotion.bounce,
  FunMotion.float,
  FunMotion.tada,
  FunMotion.pulse,
];

/// Horizontal shelf of topic "sticker" cards.
class TopicShelf extends StatelessWidget {
  const TopicShelf({super.key, required this.topics, required this.onTap});

  final List<TopicProgress> topics;
  final ValueChanged<TopicProgress> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: topics.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) =>
            _TopicCard(
                  progress: topics[i],
                  motion: _motions[i % _motions.length],
                  onTap: () => onTap(topics[i]),
                )
                .animate()
                .fadeIn(delay: (80 * i).ms, duration: 300.ms)
                .slideX(begin: 0.2, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.progress,
    required this.motion,
    required this.onTap,
  });

  final TopicProgress progress;
  final FunMotion motion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = progress.topic;

    return Semantics(
      button: true,
      label: '${t.english}: ${progress.learned} of ${progress.total} words',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Ink(
            width: 150,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: progress.recommended
                    ? t.color.withValues(alpha: 0.6)
                    : AppColors.outline,
                width: progress.recommended ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FunIcon(t.emoji, color: t.color, size: 50, motion: motion),
                    const SizedBox(width: 6),
                    if (progress.recommended)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.bloomGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Für dich',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  t.german,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  t.english,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: progress.fraction),
                    duration: 900.ms,
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: AppColors.outline,
                      color: t.color,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${progress.learned}/${progress.total} words',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
