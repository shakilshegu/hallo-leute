import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database.dart';
import '../../../data/topics.dart';
import '../../../services/speaker.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/fun_icon.dart';
import '../../../widgets/word_text.dart';

/// A vocabulary flashcard.
///
/// Front: the noun without its article – guess der / die / das first.
/// Back: article-coloured word, plural, meaning and an example sentence.
/// Tap (or [flipSignal]) flips the card in 3D.
class FlashCard extends ConsumerStatefulWidget {
  const FlashCard({
    super.key,
    required this.word,
    required this.active,
    this.onGuess,
    this.flipSignal,
  });

  final Word word;

  /// Only the top card of the deck reacts to taps.
  final bool active;
  final void Function(bool correct)? onGuess;

  /// Each change flips the card (used by the flip button).
  final ValueListenable<int>? flipSignal;

  @override
  ConsumerState<FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends ConsumerState<FlashCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _angle = CurvedAnimation(
    parent: _flip,
    curve: Curves.easeInOutBack,
  );
  Article? _guess;
  Timer? _autoFlip;

  @override
  void initState() {
    super.initState();
    widget.flipSignal?.addListener(_toggle);
  }

  @override
  void didUpdateWidget(FlashCard old) {
    super.didUpdateWidget(old);
    if (old.flipSignal != widget.flipSignal) {
      old.flipSignal?.removeListener(_toggle);
      widget.flipSignal?.addListener(_toggle);
    }
  }

  @override
  void dispose() {
    widget.flipSignal?.removeListener(_toggle);
    _autoFlip?.cancel();
    _flip.dispose();
    super.dispose();
  }

  bool get _showingBack => _flip.status.isForwardOrCompleted;

  void _toggle() {
    if (!widget.active) return;
    HapticFeedback.lightImpact();
    _showingBack ? _flip.reverse() : _flip.forward();
  }

  void _onGuess(Article a) {
    if (_guess != null || !widget.active) return;
    final correct = a == widget.word.article;
    setState(() => _guess = a);
    correct ? HapticFeedback.mediumImpact() : HapticFeedback.heavyImpact();
    widget.onGuess?.call(correct);
    _autoFlip = Timer(const Duration(milliseconds: 900), () {
      if (mounted && !_showingBack) _flip.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _showingBack
          ? '${widget.word.article?.name ?? ''} ${widget.word.german}: '
                '${widget.word.english}'
          : 'Flashcard: ${widget.word.german}. Tap to flip.',
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _angle,
          builder: (context, _) {
            final angle = _angle.value * math.pi;
            final back = angle > math.pi / 2;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0011)
                ..rotateY(angle),
              child: back
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(math.pi),
                      child: _CardBack(word: widget.word),
                    )
                  : _CardFront(
                      word: widget.word,
                      guess: _guess,
                      onGuess: _onGuess,
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

BoxDecoration _cardBox({required Color tint, required bool back}) =>
    BoxDecoration(
      color: back
          ? Color.alphaBlend(tint.withValues(alpha: 0.09), AppColors.surface)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(32),
      border: Border.all(
        color: back ? tint.withValues(alpha: 0.45) : AppColors.outline,
        width: back ? 2 : 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (back ? tint : AppColors.ink).withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ],
    );

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final topic = Topic.byId(word.topic);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (topic?.color ?? AppColors.sunrise).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${topic?.emoji ?? ''} ${topic?.german ?? word.topic} · '
        '${word.level.code}',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Round speaker button that reads [text] aloud in German.
class SpeakButton extends ConsumerWidget {
  const SpeakButton({super.key, required this.text, this.size = 40});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.square(
      dimension: size,
      child: IconButton.filledTonal(
        tooltip: 'Listen',
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink.withValues(alpha: 0.06),
          foregroundColor: AppColors.ink,
        ),
        iconSize: size * 0.5,
        onPressed: () {
          HapticFeedback.selectionClick();
          ref.read(speakerProvider).speak(text);
        },
        icon: const Icon(Icons.volume_up_rounded),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Front
// ---------------------------------------------------------------------------

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.word,
    required this.guess,
    required this.onGuess,
  });

  final Word word;
  final Article? guess;
  final ValueChanged<Article> onGuess;

  @override
  Widget build(BuildContext context) {
    final article = word.article;
    final topic = Topic.byId(word.topic);
    final guessed = guess != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: _cardBox(tint: AppColors.ink, back: false),
      child: Column(
        children: [
          Row(
            children: [
              _TopicChip(word: word),
              const Spacer(),
              // Front speaks only the noun so the article stays a surprise.
              SpeakButton(text: word.german),
            ],
          ),
          const Spacer(),
          FunIcon(
            word.emoji,
            // Topic colour, not article colour – no spoilers!
            color: topic?.color ?? AppColors.sunrise,
            size: 104,
            motion: FunMotion.float,
            tilt: -0.05,
          ),
          const SizedBox(height: 26),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (article != null) ...[
                  _ArticleSlot(article: article, revealed: guessed),
                  const SizedBox(width: 10),
                ],
                Text(
                  word.german,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (article != null) ...[
            AnimatedSwitcher(
              duration: 250.ms,
              child: Text(
                !guessed
                    ? 'Which article? Take a guess!'
                    : guess == article
                    ? 'Richtig! 🎉 Nice one.'
                    : 'Almost! It’s “${article.name}” 💪',
                key: ValueKey(guess),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: !guessed
                      ? AppColors.muted
                      : guess == article
                      ? AppColors.dasText
                      : AppColors.poppyText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final a in Article.values) ...[
                  if (a != Article.der) const SizedBox(width: 10),
                  Expanded(
                    child: _ArticleChip(
                      article: a,
                      state: !guessed
                          ? _ChipState.idle
                          : a == article
                          ? _ChipState.correct
                          : a == guess
                          ? _ChipState.wrong
                          : _ChipState.faded,
                      onTap: () => onGuess(a),
                    ),
                  ),
                ],
              ],
            ),
          ] else
            const Text(
              'Tap the card to see the meaning',
              style: TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          const SizedBox(height: 14),
          const Text(
            'Tap to flip · swipe to sort',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The blank before the noun – fills with the right article after a guess.
class _ArticleSlot extends StatelessWidget {
  const _ArticleSlot({required this.article, required this.revealed});

  final Article article;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 300.ms,
      curve: Curves.easeOutBack,
      width: 70,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: revealed ? article.textColor : AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: revealed ? article.textColor : AppColors.outline,
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: 250.ms,
        transitionBuilder: (child, a) =>
            ScaleTransition(scale: a, child: child),
        child: Text(
          revealed ? article.name : '?',
          key: ValueKey(revealed),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: revealed ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

enum _ChipState { idle, correct, wrong, faded }

class _ArticleChip extends StatelessWidget {
  const _ArticleChip({
    required this.article,
    required this.state,
    required this.onTap,
  });

  final Article article;
  final _ChipState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (state) {
      _ChipState.idle => (
        AppColors.surface,
        article.textColor,
        article.color.withValues(alpha: 0.5),
      ),
      _ChipState.correct => (
        article.textColor,
        Colors.white,
        article.textColor,
      ),
      _ChipState.wrong => (AppColors.error, Colors.white, AppColors.error),
      _ChipState.faded => (
        AppColors.surface,
        article.textColor.withValues(alpha: 0.35),
        AppColors.outline,
      ),
    };
    final icon = switch (state) {
      _ChipState.correct => ' ✓',
      _ChipState.wrong => ' ✕',
      _ => '',
    };

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: state == _ChipState.idle ? onTap : null,
        child: AnimatedContainer(
          duration: 220.ms,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 2),
          ),
          child: Text(
            '${article.name}$icon',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ),
      ),
    );

    chip = Semantics(button: true, label: article.name, child: chip);
    return switch (state) {
      _ChipState.correct =>
        chip
            .animate(key: const ValueKey('ok'))
            .scaleXY(end: 1.08, duration: 140.ms)
            .then()
            .scaleXY(end: 1 / 1.08, duration: 300.ms, curve: Curves.elasticOut),
      _ChipState.wrong =>
        chip.animate(key: const ValueKey('no')).shakeX(hz: 6, amount: 5),
      _ => chip,
    };
  }
}

// ---------------------------------------------------------------------------
// Back
// ---------------------------------------------------------------------------

class _CardBack extends StatelessWidget {
  const _CardBack({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final article = word.article;
    final tint = article?.color ?? AppColors.sunrise;
    final full = article == null
        ? word.german
        : '${article.name} ${word.german}';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: _cardBox(tint: tint, back: true),
      child: Column(
        children: [
          Row(
            children: [
              _TopicChip(word: word),
              const Spacer(),
              SpeakButton(text: full),
            ],
          ),
          const Spacer(),
          FunIcon(
            word.emoji,
            color: tint,
            size: 84,
            motion: FunMotion.tada,
            tilt: 0.05,
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  if (article != null)
                    TextSpan(
                      text: '${article.name} ',
                      style: TextStyle(color: article.textColor),
                    ),
                  TextSpan(text: word.german),
                ],
              ),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.ink,
              ),
            ),
          ),
          if (word.plural != null)
            Text(
              'Plural: ${word.plural}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          const SizedBox(height: 14),
          Text(
            word.english,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        highlightWord(word.example, word.german, article),
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        word.exampleEn,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                SpeakButton(text: word.example, size: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
