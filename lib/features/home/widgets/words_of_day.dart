import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/progress.dart';
import '../../../data/vocabulary.dart';
import '../../../services/speech.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

/// Ten swipeable flashcards for today. Tap a card to see its meaning;
/// "I know it" / "Not yet" records it in the learner's progress.
class WordsOfDay extends StatefulWidget {
  const WordsOfDay({super.key, required this.words});

  final List<GermanWord> words;

  @override
  State<WordsOfDay> createState() => _WordsOfDayState();
}

class _WordsOfDayState extends State<WordsOfDay> {
  final _pages = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _answer(GermanWord word, {required bool knewIt}) {
    HapticFeedback.lightImpact();
    ProgressScope.of(context).recordAnswer(word, knewIt: knewIt);
    // Move on to the next card, like flipping through a deck.
    if (_page < widget.words.length - 1) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          _pages.nextPage(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final progress = ProgressScope.of(context);
    return Column(
      children: [
        SizedBox(
          height: 264 * scale,
          child: PageView.builder(
            controller: _pages,
            padEnds: false,
            itemCount: widget.words.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final w = widget.words[i];
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 24 : 6, right: 6),
                child: _DayWordCard(
                  key: ValueKey('wotd-${w.word}-${w.pos}'),
                  word: w,
                  index: i,
                  total: widget.words.length,
                  status: progress.statusOf(w),
                  onKnow: () => _answer(w, knewIt: true),
                  onNotYet: () => _answer(w, knewIt: false),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _Dots(count: widget.words.length, active: _page),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == active
                  ? AppColors.mustard
                  : AppColors.cream.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
      ],
    );
  }
}

class _DayWordCard extends StatefulWidget {
  const _DayWordCard({
    super.key,
    required this.word,
    required this.index,
    required this.total,
    required this.status,
    required this.onKnow,
    required this.onNotYet,
  });

  final GermanWord word;
  final int index;
  final int total;
  final WordStatus status;
  final VoidCallback onKnow;
  final VoidCallback onNotYet;

  @override
  State<_DayWordCard> createState() => _DayWordCardState();
}

class _DayWordCardState extends State<_DayWordCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
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
    final german = [w.article, w.word].where((s) => s.isNotEmpty).join(' ');
    final learned =
        widget.status == WordStatus.learning ||
        widget.status == WordStatus.mastered;
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _toggle,
            child: Semantics(
              button: true,
              label: '$german. Tap to see the meaning.',
              child: AnimatedBuilder(
                animation: _flip,
                builder: (context, _) {
                  final t = Curves.easeInOutCubic.transform(_flip.value);
                  final back = t >= 0.5;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0012)
                      ..rotateY(back ? t * math.pi - math.pi : t * math.pi),
                    child: _Face(
                      back: back,
                      word: w,
                      german: german,
                      label: 'WORD ${widget.index + 1} OF ${widget.total}',
                      learned: learned,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: learned
                ? Container(
                    key: const ValueKey('learned'),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.mustard.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.mustard,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Learned · in your words',
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              14,
                              weight: FontWeight.w800,
                              color: AppColors.mustard,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    key: const ValueKey('ask'),
                    children: [
                      Expanded(
                        child: _SmallButton(
                          label: 'Not yet',
                          onTap: widget.onNotYet,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _SmallButton(
                          label: 'I know it',
                          primary: true,
                          onTap: widget.onKnow,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _Face extends StatelessWidget {
  const _Face({
    required this.back,
    required this.word,
    required this.german,
    required this.label,
    required this.learned,
  });

  final bool back;
  final GermanWord word;
  final String german;
  final String label;
  final bool learned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: back
            ? AppColors.cream
            : AppColors.navy800.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(22),
        border: back
            ? null
            : Border.all(color: AppColors.navyLine.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.body(
                    11,
                    weight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: back ? AppColors.navy700 : AppColors.creamMuted,
                  ),
                ),
              ),
              SpeakButton(
                text: back && word.hasExample ? word.example : german,
                size: 36,
                onLight: back,
              ),
            ],
          ),
          Expanded(
            child: back
                ? _back()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              if (word.article.isNotEmpty)
                                TextSpan(
                                  text: '${word.article} ',
                                  style: AppText.display(
                                    32,
                                    color: AppColors.mustard,
                                  ),
                                ),
                              TextSpan(
                                text: word.word,
                                style: AppText.display(
                                  32,
                                  color: AppColors.cream,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap to see the meaning',
                        style: AppText.body(
                          13,
                          weight: FontWeight.w700,
                          color: AppColors.mustard.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _back() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          german,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.display(20, color: AppColors.navy),
        ),
        Text(
          word.meaning,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.body(
            16,
            weight: FontWeight.w800,
            color: AppColors.mustardDeep,
            height: 1.25,
          ),
        ),
        if (word.hasExample) ...[
          const SizedBox(height: 10),
          Text(
            word.example,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              14.5,
              weight: FontWeight.w700,
              color: AppColors.navy,
              height: 1.3,
            ),
          ),
          Text(
            word.exampleMeaning,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(13, color: AppColors.navy700, height: 1.3),
          ),
        ],
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Material(
      color: primary ? AppColors.cream : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: primary
            ? BorderSide.none
            : BorderSide(color: AppColors.cream.withValues(alpha: 0.22)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(
              14.5,
              weight: FontWeight.w800,
              color: primary ? AppColors.navy : AppColors.cream,
            ),
          ),
        ),
      ),
    );
  }
}
