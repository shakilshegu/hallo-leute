import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../../../data/vocabulary.dart';
import '../../../services/speech.dart';
import '../home_content.dart';

/// Small uppercase section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              12,
              weight: FontWeight.w800,
              color: AppColors.creamMuted,
              letterSpacing: 1.3,
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            trailing!,
            style: AppText.body(12.5, color: AppColors.creamMuted),
          ),
        ],
      ],
    );
  }
}

/// Wraps a child with a gentle press-down scale and a tap handler.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.semanticLabel,
  });

  final VoidCallback onTap;
  final Widget child;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: widget.child,
        ),
      ),
    );
  }
}

// ───────────────────────────── Today ─────────────────────────────

/// The one primary action on the home screen.
class TodayCard extends StatelessWidget {
  const TodayCard({
    super.key,
    required this.learned,
    required this.goal,
    required this.minutes,
    required this.onStart,
  });

  final int learned;
  final int goal;
  final int minutes;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final done = learned >= goal;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProgressRing(
                value: goal == 0 ? 0 : learned / goal,
                size: 76,
              ).withCenter(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$learned',
                      style: AppText.display(
                        22,
                        color: AppColors.navy,
                        height: 1,
                      ),
                    ),
                    Text(
                      'of $goal',
                      style: AppText.body(
                        11.5,
                        weight: FontWeight.w700,
                        color: AppColors.navy700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S GOAL",
                      style: AppText.body(
                        11.5,
                        weight: FontWeight.w800,
                        color: AppColors.navy700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      done ? 'Goal reached!' : '$goal new words',
                      style: AppText.display(
                        22,
                        color: AppColors.navy,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'About $minutes min',
                      style: AppText.body(13.5, color: AppColors.navy700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: onStart,
            semanticLabel: done ? 'Practice more' : 'Start lesson',
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      done ? 'Practice more' : 'Start lesson',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.display(
                        17,
                        weight: FontWeight.w600,
                        color: AppColors.cream,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: AppColors.mustard,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when learned words are due again (spaced repetition).
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.due, required this.onStart});

  final int due;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _ReviewTile(
    title: 'Review',
    body: due == 1
        ? '1 word is ready to refresh'
        : '$due words are ready to refresh',
    semanticLabel: 'Review $due words',
    icon: Icons.replay_rounded,
    highlighted: true,
    onTap: onStart,
  );
}

/// Flashcards of learned words on demand, weakest first. Early answers don't
/// change the review schedule (see LearningProgress.recordAnswer).
class ReviewAnytimeCard extends StatelessWidget {
  const ReviewAnytimeCard({
    super.key,
    required this.learned,
    required this.onStart,
  });

  final int learned;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => _ReviewTile(
    title: 'Review my words',
    body:
        'Flip through the $learned ${learned == 1 ? 'word' : 'words'} '
        'you learned. Weakest first.',
    semanticLabel: 'Review my $learned learned words',
    icon: Icons.style_outlined,
    highlighted: false,
    onTap: onStart,
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.title,
    required this.body,
    required this.semanticLabel,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  final String title;
  final String body;
  final String semanticLabel;
  final IconData icon;

  /// Mustard border for due reviews; quieter for optional ones.
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.navy800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted
                ? AppColors.mustard.withValues(alpha: 0.45)
                : AppColors.navyLine.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.mustard.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: AppColors.mustard),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.body(
                      15.5,
                      weight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  Text(
                    body,
                    style: AppText.body(13.5, color: AppColors.creamMuted),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: AppColors.mustard,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular progress that animates to [value] (0–1).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.size = 72,
    this.center,
  });

  final double value;
  final double size;
  final Widget? center;

  ProgressRing withCenter(Widget child) =>
      ProgressRing(value: value, size: size, center: child);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Daily progress',
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          size: Size.square(size),
          painter: _RingPainter(v),
          child: SizedBox.square(dimension: size, child: child),
        ),
        child: Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.navy.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        math.pi * 2 * value,
        false,
        Paint()
          ..color = AppColors.mustardDeep
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ─────────────────────────── Word of the day ───────────────────────────

/// Tap to flip between the word and an example sentence.
class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key, required this.word});

  final GermanWord word;

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _flip.value = _flip.value < 0.5 ? 1 : 0;
    } else if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.word;
    return Pressable(
      onTap: _toggle,
      semanticLabel:
          '${w.article} ${w.word}, ${w.meaning}. Tap to flip for an example.',
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_flip.value);
          final showBack = t >= 0.5;
          final angle = t * math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(showBack ? angle - math.pi : angle),
            child: _WordFace(word: w, back: showBack),
          );
        },
      ),
    );
  }
}

class _WordFace extends StatelessWidget {
  const _WordFace({required this.word, required this.back});

  final GermanWord word;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: back
                  ? [
                      Text(
                        word.example,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.display(
                          20,
                          color: AppColors.cream,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        word.exampleMeaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(14, color: AppColors.creamMuted),
                      ),
                    ]
                  : [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${word.article} ',
                              style: AppText.display(
                                26,
                                color: AppColors.mustard,
                              ),
                            ),
                            TextSpan(
                              text: word.word,
                              style: AppText.display(
                                26,
                                color: AppColors.cream,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.meaning,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(15, color: AppColors.creamMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap for an example',
                        style: AppText.body(
                          12,
                          weight: FontWeight.w700,
                          color: AppColors.mustard.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
            ),
          ),
          const SizedBox(width: 12),
          SpeakButton(
            text: back
                ? word.example
                : [
                    word.article,
                    word.word,
                  ].where((s) => s.isNotEmpty).join(' '),
            size: 42,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── This week ─────────────────────────────

/// Mon–Sun strip with German day names; practised days are filled.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.today, required this.practised});

  final DateTime today;

  /// Weekday numbers (1 = Monday … 7 = Sunday) practised this week.
  final Set<int> practised;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          _Day(
            label: germanWeekdays[i],
            isToday: today.weekday == i + 1,
            done: practised.contains(i + 1),
            future: i + 1 > today.weekday,
          ),
      ],
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({
    required this.label,
    required this.isToday,
    required this.done,
    required this.future,
  });

  final String label;
  final bool isToday;
  final bool done;
  final bool future;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppText.body(
            12.5,
            weight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? AppColors.cream : AppColors.creamMuted,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.mustard
                : AppColors.cream.withValues(alpha: future ? 0.03 : 0.06),
            border: isToday && !done
                ? Border.all(color: AppColors.mustard, width: 1.6)
                : null,
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 18, color: AppColors.navy)
              : null,
        ),
      ],
    );
  }
}

// ───────────────────────────── Topics ─────────────────────────────

class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.topic,
    required this.learned,
    required this.onTap,
  });

  final Topic topic;
  final int learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = topic.wordCount == 0 ? 0.0 : learned / topic.wordCount;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${topic.english}, ${topic.german}',
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(topic.icon, size: 24, color: AppColors.mustard),
            Text(
              topic.german,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                15,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
            Text(
              topic.english,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(13, color: AppColors.creamMuted),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: AppColors.mustard,
                backgroundColor: AppColors.cream.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$learned / ${topic.wordCount} words',
              style: AppText.body(11.5, color: AppColors.creamMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wide card for a career pack (Pflege, IT & Büro) on Home.
class PackCard extends StatelessWidget {
  const PackCard({
    super.key,
    required this.topic,
    required this.learned,
    required this.onTap,
  });

  final Topic topic;
  final int learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = topic.wordCount;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${topic.german}, ${topic.english}. $learned of $total',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navy800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.mustard.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(topic.icon, color: AppColors.mustard, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.german,
                    style: AppText.body(
                      16,
                      weight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  Text(
                    topic.english,
                    style: AppText.body(13, color: AppColors.creamMuted),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : learned / total,
                      minHeight: 4,
                      color: AppColors.mustard,
                      backgroundColor: AppColors.cream.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$learned/$total',
              style: AppText.body(
                13,
                weight: FontWeight.w800,
                color: AppColors.creamMuted,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.creamMuted,
            ),
          ],
        ),
      ),
    );
  }
}
