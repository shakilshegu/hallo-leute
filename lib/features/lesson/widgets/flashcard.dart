import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/vocabulary.dart';
import '../../../services/speech.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

const _posLabels = {
  'noun': 'noun',
  'verb': 'verb',
  'adj': 'adjective',
  'adv': 'adverb',
  'prep': 'preposition',
  'conj': 'conjunction',
  'pron': 'pronoun',
  'det': 'determiner',
  'intj': 'interjection',
  'num': 'number',
  'particle': 'particle',
};

/// A word card that flips (3D) between the German word and its meaning.
class Flashcard extends StatelessWidget {
  const Flashcard({super.key, required this.word, required this.flip});

  final GermanWord word;

  /// 0 = front (German), 1 = back (meaning).
  final Animation<double> flip;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flip,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(flip.value);
        final back = t >= 0.5;
        final angle = t * math.pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0011)
            ..rotateY(back ? angle - math.pi : angle),
          child: back ? _Back(word: word) : _Front(word: word),
        );
      },
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.light = false});

  final Widget child;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: light ? AppColors.cream : AppColors.navy800,
        borderRadius: BorderRadius.circular(32),
        border: light
            ? null
            : Border.all(color: AppColors.navyLine.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy950.withValues(alpha: 0.5),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Front extends StatelessWidget {
  const _Front({required this.word});

  final GermanWord word;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _PosChip(label: _posLabels[word.pos] ?? 'phrase', light: false),
          const Spacer(),
          if (word.article.isNotEmpty)
            Text(
              word.article,
              style: AppText.display(26, color: AppColors.mustard),
            ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word.word,
              style: AppText.display(46, color: AppColors.cream, height: 1.1),
            ),
          ),
          const SizedBox(height: 20),
          SpeakButton(
            text: [
              word.article,
              word.word,
            ].where((s) => s.isNotEmpty).join(' '),
            size: 52,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.touch_app_outlined,
                size: 18,
                color: AppColors.creamMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Tap to see the meaning',
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body(13.5, color: AppColors.creamMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.word});

  final GermanWord word;

  @override
  Widget build(BuildContext context) {
    final german = [
      word.article,
      word.word,
    ].where((s) => s.isNotEmpty).join(' ');
    return _CardShell(
      light: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Like the sketch: German word, its meaning, then an example.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FittedBox(
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
                              color: AppColors.mustardDeep,
                            ),
                          ),
                        TextSpan(
                          text: word.word,
                          style: AppText.display(32, color: AppColors.navy),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SpeakButton(text: german, size: 40, onLight: true),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.meaning,
                    style: AppText.body(
                      20,
                      weight: FontWeight.w800,
                      color: AppColors.navy700,
                      height: 1.25,
                    ),
                  ),
                  if (word.plural.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text.rich(
                      TextSpan(
                        text: 'Plural  ',
                        style: AppText.body(
                          13,
                          weight: FontWeight.w800,
                          color: AppColors.navy700,
                        ),
                        children: [
                          TextSpan(
                            text: 'die ${word.plural}',
                            style: AppText.body(
                              15,
                              weight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (word.hasExample)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: const Border(
                  left: BorderSide(color: AppColors.mustardDeep, width: 3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.example,
                          style: AppText.body(
                            16,
                            weight: FontWeight.w800,
                            color: AppColors.navy,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.exampleMeaning,
                          style: AppText.body(
                            14,
                            color: AppColors.navy700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SpeakButton(text: word.example, size: 36, onLight: true),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PosChip extends StatelessWidget {
  const _PosChip({required this.label, required this.light});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: AppText.body(
          12.5,
          weight: FontWeight.w700,
          color: AppColors.creamMuted,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
