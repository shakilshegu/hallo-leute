import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../services/speech.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A word in a list: article + word, meaning, status badge, 🔊, and an
/// expandable panel with plural, the learner's history and an example.
class WordRow extends StatelessWidget {
  const WordRow({
    super.key,
    required this.word,
    required this.progress,
    required this.open,
    required this.onTap,
  });

  final GermanWord word;

  /// This learner's history with the word; null if never seen.
  final WordProgress? progress;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final learned = progress?.learnedOn != null;
    final expandable = word.hasExample || word.plural.isNotEmpty || learned;
    return Semantics(
      button: expandable,
      expanded: expandable ? open : null,
      child: InkWell(
        onTap: expandable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.cream.withValues(alpha: 0.04),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              if (word.article.isNotEmpty)
                                TextSpan(
                                  text: '${word.article} ',
                                  style: AppText.display(
                                    18,
                                    color: AppColors.mustard,
                                  ),
                                ),
                              TextSpan(
                                text: word.word,
                                style: AppText.display(
                                  18,
                                  color: AppColors.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          word.meaning,
                          style: AppText.body(14, color: AppColors.creamMuted),
                        ),
                      ],
                    ),
                  ),
                  if (learned) ...[
                    StatusBadge(status: progress!.status),
                    const SizedBox(width: 6),
                  ],
                  SpeakButton(
                    text: [
                      word.article,
                      word.word,
                    ].where((s) => s.isNotEmpty).join(' '),
                    size: 34,
                  ),
                  const SizedBox(width: 2),
                  if (expandable)
                    AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: open ? AppColors.mustard : AppColors.creamMuted,
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: open && expandable
                    ? Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: AppColors.mustard,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (word.plural.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: word.hasExample ? 8 : 0,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Plural  ',
                                    style: AppText.body(
                                      12.5,
                                      weight: FontWeight.w800,
                                      color: AppColors.creamMuted,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'die ${word.plural}',
                                        style: AppText.body(
                                          14,
                                          weight: FontWeight.w700,
                                          color: AppColors.cream,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (learned)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      word.hasExample || word.plural.isNotEmpty
                                      ? 10
                                      : 0,
                                ),
                                child: WordHistory(progress: progress!),
                              ),
                            if (word.hasExample)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          word.example,
                                          style: AppText.body(
                                            15,
                                            weight: FontWeight.w700,
                                            color: AppColors.cream,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          word.exampleMeaning,
                                          style: AppText.body(
                                            13.5,
                                            color: AppColors.creamMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SpeakButton(text: word.example, size: 32),
                                ],
                              ),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final WordStatus status;

  @override
  Widget build(BuildContext context) {
    final mastered = status == WordStatus.mastered;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: mastered
            ? AppColors.mustard
            : AppColors.mustard.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        mastered ? 'Mastered' : 'Learning',
        style: AppText.body(
          11,
          weight: FontWeight.w800,
          color: mastered ? AppColors.navy : AppColors.mustard,
        ),
      ),
    );
  }
}

/// "Learned 16 Nov · seen 4× · next review in 3 days".
class WordHistory extends StatelessWidget {
  const WordHistory({super.key, required this.progress});

  final WordProgress progress;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final learned = p.learnedOn!;
    final today = ProgressScope.of(context).today;
    // Compare calendar days in UTC so daylight-saving shifts don't skew it.
    final days = DateTime.utc(
      p.due.year,
      p.due.month,
      p.due.day,
    ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
    final next = days <= 0
        ? 'review today'
        : days == 1
        ? 'next review tomorrow'
        : 'next review in $days days';
    return Text(
      'Learned ${learned.day} ${_months[learned.month - 1]} · '
      'seen ${p.timesSeen}× · $next',
      style: AppText.body(
        12.5,
        weight: FontWeight.w700,
        color: AppColors.mustard,
      ),
    );
  }
}
