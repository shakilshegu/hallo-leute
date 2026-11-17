import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/fill_or_scroll.dart';
import '../../shared/widgets/primary_button.dart';
import '../../services/reminders.dart';
import '../../theme/app_colors.dart';
import '../profile/reminder_card.dart';
import '../share/share_progress.dart';
import '../../theme/app_text.dart';
import 'widgets/flashcard.dart';

/// Flashcard session: flip to reveal, then "Got it" (swipe right) or
/// "Again" (swipe left). "Again" cards come back later in the session.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.words, this.review = false});

  final List<GermanWord> words;

  /// Reviewing words learned before (spaced repetition) instead of new ones.
  final bool review;

  static Route<void> route(List<GermanWord> words, {bool review = false}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => LessonScreen(words: words, review: review),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with TickerProviderStateMixin {
  late final List<GermanWord> _queue = [...widget.words];
  final _missed = <GermanWord>{};
  int _learned = 0;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  /// Drives a card flying off (or springing back) after a swipe/answer.
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  Offset _drag = Offset.zero;
  Animation<Offset>? _flyTween;

  bool get _revealed =>
      _flip.value > 0.5 || _flip.status == AnimationStatus.forward;
  bool get _done => _queue.isEmpty;
  int get _total => widget.words.length;

  @override
  void initState() {
    super.initState();
    _flip.addStatusListener((_) => setState(() {}));
  }

  @override
  void dispose() {
    _flip.dispose();
    _fly.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  void _toggleFlip() {
    if (_fly.isAnimating) return;
    HapticFeedback.selectionClick();
    if (_reduceMotion) {
      _flip.value = _flip.value < 0.5 ? 1 : 0;
    } else if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  Future<void> _answer(bool knewIt) async {
    if (_done || _fly.isAnimating) return;
    HapticFeedback.lightImpact();
    final width = MediaQuery.sizeOf(context).width;
    await _animateTo(Offset((knewIt ? 1.4 : -1.4) * width, _drag.dy + 40));
    if (!mounted) return;

    final word = _queue.removeAt(0);
    // Every answer is recorded: it schedules the word's next review.
    ProgressScope.of(context).recordAnswer(word, knewIt: knewIt);
    if (knewIt) {
      _learned++;
    } else {
      _missed.add(word);
      // Bring it back after a couple of other cards.
      _queue.insert(math.min(2, _queue.length), word);
    }
    setState(() {
      _drag = Offset.zero;
      _flyTween = null;
      _flip.value = 0;
    });
  }

  Future<void> _animateTo(Offset target) async {
    if (_reduceMotion) return;
    _flyTween = Tween(
      begin: _drag,
      end: target,
    ).animate(CurvedAnimation(parent: _fly, curve: Curves.easeOutCubic));
    await _fly.forward(from: 0);
  }

  void _onDragEnd(DragEndDetails d) {
    final width = MediaQuery.sizeOf(context).width;
    final vx = d.velocity.pixelsPerSecond.dx;
    if (_drag.dx > width * 0.28 || vx > 900) {
      _answer(true);
    } else if (_drag.dx < -width * 0.28 || vx < -900) {
      _answer(false);
    } else {
      _animateTo(Offset.zero).then((_) {
        if (mounted) setState(() => _drag = Offset.zero);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _done
                    ? _Summary(
                        key: const ValueKey('summary'),
                        learned: _learned,
                        missed: _missed.length,
                        review: widget.review,
                        onDone: () => Navigator.of(context).pop(),
                      )
                    : _session(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _session() {
    final progress = _total == 0 ? 0.0 : _learned / _total;
    return Column(
      key: const ValueKey('session'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Close lesson',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.cream),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: progress),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      color: AppColors.mustard,
                      backgroundColor: AppColors.cream.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$_learned/$_total',
                style: AppText.body(
                  13,
                  weight: FontWeight.w800,
                  color: AppColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: _CardStack(
              current: _queue.first,
              next: _queue.length > 1 ? _queue[1] : null,
              flip: _flip,
              fly: _fly,
              offset: () => _flyTween?.value ?? _drag,
              onTap: _toggleFlip,
              onDragUpdate: (d) {
                if (_fly.isAnimating) return;
                setState(() => _drag += d.delta);
              },
              onDragEnd: _onDragEnd,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _revealed
                ? Row(
                    key: const ValueKey('answers'),
                    children: [
                      Expanded(
                        child: _AnswerButton(
                          label: 'Again',
                          icon: Icons.replay_rounded,
                          onTap: () => _answer(false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnswerButton(
                          label: 'Got it',
                          icon: Icons.check_rounded,
                          primary: true,
                          onTap: () => _answer(true),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    key: const ValueKey('hint'),
                    height: 60,
                    child: Center(
                      child: Text(
                        'Swipe right if you know it, left to see it again',
                        textAlign: TextAlign.center,
                        style: AppText.body(13.5, color: AppColors.creamMuted),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _CardStack extends StatelessWidget {
  const _CardStack({
    required this.current,
    required this.next,
    required this.flip,
    required this.fly,
    required this.offset,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final GermanWord current;
  final GermanWord? next;
  final Animation<double> flip;
  final Animation<double> fly;
  final Offset Function() offset;
  final VoidCallback onTap;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return AnimatedBuilder(
          animation: fly,
          builder: (context, _) {
            final o = offset();
            final pull = (o.dx.abs() / (width * 0.6)).clamp(0.0, 1.0);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                if (next != null)
                  Positioned.fill(
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - pull)),
                      child: Transform.scale(
                        scale: 0.94 + 0.06 * pull,
                        child: Opacity(
                          opacity: 0.5 + 0.5 * pull,
                          child: ExcludeSemantics(
                            child: Flashcard(
                              key: ValueKey('next-${next!.word}'),
                              word: next!,
                              flip: const AlwaysStoppedAnimation(0),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: o,
                    child: Transform.rotate(
                      angle: o.dx / width * 0.25,
                      child: GestureDetector(
                        key: const ValueKey('flashcard'),
                        onTap: onTap,
                        onPanUpdate: onDragUpdate,
                        onPanEnd: onDragEnd,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Semantics(
                                button: true,
                                label: 'Flashcard. Tap to flip.',
                                child: Flashcard(
                                  key: ValueKey('card-${current.word}'),
                                  word: current,
                                  flip: flip,
                                ),
                              ),
                            ),
                            _SwipeStamp(dx: o.dx, width: width),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// "Got it" / "Again" label that fades in while dragging.
class _SwipeStamp extends StatelessWidget {
  const _SwipeStamp({required this.dx, required this.width});

  final double dx;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = (dx.abs() / (width * 0.28)).clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.shrink();
    final right = dx > 0;
    // On the trailing side, which stays on screen while the card moves away.
    return Positioned.fill(
      child: Align(
        alignment: Alignment(right ? -0.7 : 0.7, 0.15),
        child: Opacity(
          opacity: t,
          child: Transform.rotate(
            angle: right ? -0.15 : 0.15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: right ? AppColors.mustard : AppColors.creamMuted,
                  width: 2.5,
                ),
              ),
              child: Text(
                right ? 'GOT IT' : 'AGAIN',
                style: AppText.display(
                  18,
                  color: right ? AppColors.mustard : AppColors.creamMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    return Material(
      color: primary ? AppColors.cream : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: primary
            ? BorderSide.none
            : BorderSide(color: AppColors.cream.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: primary ? AppColors.mustardDeep : AppColors.creamMuted,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.display(
                    18,
                    weight: FontWeight.w600,
                    color: primary ? AppColors.navy : AppColors.cream,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    super.key,
    required this.learned,
    required this.missed,
    required this.review,
    required this.onDone,
  });

  final int learned;
  final int missed;
  final bool review;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final reminders = RemindersScope.maybeOf(context);
    return FillOrScroll(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, s, child) =>
              Transform.scale(scale: s, child: child),
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.mustard,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 52,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Super gemacht!',
          style: AppText.display(32, color: AppColors.cream),
        ),
        const SizedBox(height: 6),
        Text(
          review
              ? 'Great job! You reviewed $learned '
                    '${learned == 1 ? 'word' : 'words'}.'
              : 'Great job! You learned $learned new '
                    '${learned == 1 ? 'word' : 'words'}.',
          textAlign: TextAlign.center,
          style: AppText.body(15.5, color: AppColors.creamMuted, height: 1.4),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: _SummaryStat(
                value: '$learned',
                label: review ? 'Reviewed' : 'Learned',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStat(value: '$missed', label: 'Practised again'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryStat(
                value: '${progress.streak}',
                label: 'Day streak',
              ),
            ),
          ],
        ),
        const Spacer(),
        if (reminders != null &&
            !reminders.settings.enabled &&
            !reminders.settings.offered) ...[
          ReminderOffer(reminders: reminders),
          const SizedBox(height: 16),
        ],
        const Spacer(),
        PrimaryButton(label: 'Back to home', onPressed: onDone),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () => showShareProgress(context),
          icon: const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('Share my progress'),
          style: TextButton.styleFrom(foregroundColor: AppColors.cream),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.body(12, color: AppColors.creamMuted),
          ),
        ],
      ),
    );
  }
}
