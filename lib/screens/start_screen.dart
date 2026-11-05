import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../theme/app_theme.dart';
import '../widgets/poppy_logo.dart';
import '../widgets/poppy_mascot.dart';

/// Welcome screen – "Word Bloom".
///
/// A poppy whose petals are German flashcards, each coloured by its
/// article (der / die / das), with greeting bubbles floating around it.
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _SoftAura()),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _WordBloom(animation: _anim)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
                  child: Column(
                    children: [
                      const PoppyWordmark(size: 20),
                      const SizedBox(height: 18),
                      Text(
                        'Deutsch lernen.',
                        textAlign: TextAlign.center,
                        style: text.displayMedium,
                      ),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (b) => const LinearGradient(
                          colors: [
                            AppColors.poppy,
                            AppColors.sunrise,
                            AppColors.lavender,
                          ],
                        ).createShader(b),
                        child: Text(
                          'Wort für Wort.',
                          textAlign: TextAlign.center,
                          style: text.displayMedium,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Bite-sized German vocabulary.\nA few fun minutes a day 🌸',
                        textAlign: TextAlign.center,
                        style: text.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: FilledButton(
                    onPressed: () => context.go(Routes.onboarding),
                    child: const Text('Get Started'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

/// Cream background with three soft colour glows.
class _SoftAura extends StatelessWidget {
  const _SoftAura();

  @override
  Widget build(BuildContext context) {
    Widget glow(Alignment at, Color color, double size) => Align(
      alignment: at,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );

    return ColoredBox(
      color: AppColors.cream,
      child: Stack(
        children: [
          glow(const Alignment(-1.2, -0.9), AppColors.der, 380),
          glow(const Alignment(1.3, -0.4), AppColors.die, 420),
          glow(const Alignment(0, 0.1), AppColors.sunrise, 360),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Word Bloom hero
// ---------------------------------------------------------------------------

class _Word {
  const _Word(this.article, this.word, this.english, this.emoji);

  final Article article;
  final String word;
  final String english;
  final String emoji;
}

class _WordBloom extends StatelessWidget {
  const _WordBloom({required this.animation});

  final Animation<double> animation;

  /// Petal index (-2..2) → word. Painted outer petals first.
  static const _petals = <int, _Word>{
    -2: _Word(Article.der, 'Apfel', 'apple', '🍎'),
    2: _Word(Article.die, 'Sonne', 'sun', '☀️'),
    -1: _Word(Article.das, 'Buch', 'book', '📖'),
    1: _Word(Article.der, 'Kaffee', 'coffee', '☕'),
    0: _Word(Article.die, 'Blume', 'flower', '🌸'),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cardH = math.min(h * 0.5, 200.0);
        final cardW = cardH * 0.72;
        final stem = cardH * 0.32; // distance from card bottom to pivot
        // Vertically centre the whole bloom (cards + flower centre).
        final pivot = Offset(
          w / 2,
          h / 2 + (stem + cardH * 0.78) / 2 + cardH * 0.2,
        );

        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value * 2 * math.pi;
            final spread = 0.27 + 0.02 * math.sin(t); // petal gap (rad)
            final sway = 0.035 * math.sin(t * 0.5); // whole bloom tilt

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Petals (flashcards)
                for (final e in _petals.entries)
                  Positioned(
                    left: pivot.dx - cardW / 2,
                    top: pivot.dy - stem - cardH,
                    width: cardW,
                    height: cardH,
                    child: Transform.rotate(
                      angle: e.key * spread + sway,
                      origin: Offset(0, cardH / 2 + stem),
                      child: _FlashcardPetal(
                        word: e.value,
                        highlighted: e.key == 0,
                      ),
                    ),
                  ),

                // Flower centre
                Positioned(
                  left: pivot.dx - cardH * 0.22,
                  top: pivot.dy - cardH * 0.22,
                  child: Container(
                    padding: EdgeInsets.all(cardH * 0.04),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.poppy.withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: PoppyMascot(size: cardH * 0.4),
                  ),
                ),

                // Floating greeting bubbles
                _bob(
                  t,
                  0.0,
                  const Alignment(-0.92, -0.92),
                  const _SpeechBubble('Hallo! 👋', tailLeft: true),
                ),
                _bob(
                  t,
                  2.1,
                  const Alignment(0.94, -0.62),
                  const _SpeechBubble('Danke! 🙏', tailLeft: false),
                ),
                _bob(
                  t,
                  4.2,
                  const Alignment(-0.9, 0.78),
                  const _ArticleDot(Article.der),
                ),
                _bob(
                  t,
                  1.0,
                  const Alignment(0.9, 0.78),
                  const _ArticleDot(Article.das),
                ),
                _bob(
                  t,
                  3.1,
                  const Alignment(0.55, -1.0),
                  const _ArticleDot(Article.die),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Gently floats [child] up and down.
  Widget _bob(double t, double phase, Alignment at, Widget child) {
    return Align(
      alignment: at,
      child: Transform.translate(
        offset: Offset(0, 6 * math.sin(t + phase)),
        child: child,
      ),
    );
  }
}

class _FlashcardPetal extends StatelessWidget {
  const _FlashcardPetal({required this.word, required this.highlighted});

  final _Word word;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final a = word.article;

    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxHeight / 210; // scale factor

        return Container(
          padding: EdgeInsets.all(12 * s),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(
              color: a.color.withValues(alpha: highlighted ? 0.9 : 0.25),
              width: highlighted ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: a.color.withValues(alpha: 0.22),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * s,
                  vertical: 4 * s,
                ),
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.name,
                  style: TextStyle(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w800,
                    color: a.textColor,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(word.emoji, style: TextStyle(fontSize: 46 * s)),
              ),
              const Spacer(),
              Center(
                child: Text(
                  word.word,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 20 * s,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              Center(
                child: Text(
                  word.english,
                  style: TextStyle(fontSize: 12 * s, color: AppColors.muted),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble(this.text, {required this.tailLeft});

  final String text;
  final bool tailLeft;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const tail = Radius.circular(4);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: tailLeft ? tail : r,
          bottomRight: tailLeft ? r : tail,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _ArticleDot extends StatelessWidget {
  const _ArticleDot(this.article);

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: article.textColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: article.color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        article.name,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
