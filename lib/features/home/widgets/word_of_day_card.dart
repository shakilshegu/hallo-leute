import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/database.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/fun_icon.dart';
import '../../../widgets/word_text.dart';

/// "Wort des Tages" – a card that flips in 3D to reveal the meaning.
class WordOfDayCard extends StatefulWidget {
  const WordOfDayCard({super.key, required this.word});

  final Word word;

  @override
  State<WordOfDayCard> createState() => _WordOfDayCardState();
}

class _WordOfDayCardState extends State<WordOfDayCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final Animation<double> _angle = CurvedAnimation(
    parent: _flip,
    curve: Curves.easeInOutBack,
  );

  void _toggle() {
    HapticFeedback.lightImpact();
    _flip.status.isForwardOrCompleted ? _flip.reverse() : _flip.forward();
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Word of the day. Tap to flip.',
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _angle,
          builder: (context, _) {
            final angle = _angle.value * math.pi;
            final showBack = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: showBack
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _Back(word: widget.word),
                    )
                  : _Front(word: widget.word),
            );
          },
        ),
      ),
    );
  }
}

const _cardHeight = 176.0;

BoxDecoration _cardDecoration(Color tint, {required bool back}) =>
    BoxDecoration(
      color: back
          ? Color.alphaBlend(tint.withValues(alpha: 0.1), AppColors.surface)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: tint.withValues(alpha: back ? 0.5 : 0.25)),
      boxShadow: [
        BoxShadow(
          color: tint.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );

class _Front extends StatelessWidget {
  const _Front({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final article = word.article;
    final tint = article?.color ?? AppColors.sunrise;

    return Container(
      height: _cardHeight,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(tint, back: false),
      child: Row(
        children: [
          FunIcon(
            word.emoji,
            color: tint,
            size: 72,
            motion: FunMotion.float,
            tilt: -0.08,
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (article != null)
                  Text(
                    article.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: article.textColor,
                    ),
                  ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    word.german,
                    style: const TextStyle(
                      fontSize: 32,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (word.plural != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Plural: ${word.plural}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tap to reveal',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final tint = word.article?.color ?? AppColors.sunrise;

    return Container(
      height: _cardHeight,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(tint, back: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${word.emoji}  ${word.english}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            highlightWord(word.example, word.german, word.article),
            style: const TextStyle(
              fontSize: 16,
              height: 1.35,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            word.exampleEn,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
