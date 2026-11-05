import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/poppy_mascot.dart';
import '../home/widgets/petal_bloom.dart';
import 'learn_session.dart';
import 'widgets/flash_card.dart';
import 'widgets/flying_petal.dart';
import 'widgets/session_complete.dart';
import 'widgets/swipe_deck.dart';

/// Full-screen flashcard session (the dock is hidden for focus).
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, this.topic});

  /// Optional topic id to study only that topic.
  final String? topic;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final _swipe = SwipeController();
  final _flip = ValueNotifier<int>(0);
  final _stackKey = GlobalKey();
  final _bloomKey = GlobalKey();
  final _deckKey = GlobalKey();
  final _petals = <(int, Offset, Offset, Color)>[];
  var _petalId = 0;

  @override
  void dispose() {
    _swipe.dispose();
    _flip.dispose();
    super.dispose();
  }

  LearnSession get _session =>
      ref.read(learnSessionProvider(widget.topic).notifier);

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }

  Offset? _centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || stack == null || !box.hasSize) return null;
    return stack.globalToLocal(box.localToGlobal(box.size.center(Offset.zero)));
  }

  void _onSwiped(SwipeDir dir, SessionState s) {
    final card = s.current;
    if (card == null) return;
    if (dir == SwipeDir.right) {
      final from = _centerOf(_deckKey);
      final to = _centerOf(_bloomKey);
      if (from != null && to != null) {
        setState(
          () => _petals.add((
            _petalId++,
            from,
            to,
            card.word.article?.color ?? AppColors.sunrise,
          )),
        );
      }
      _session.know();
    } else {
      HapticFeedback.selectionClick();
      _session.again();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(learnSessionProvider(widget.topic));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          key: _stackKey,
          children: [
            async.when(
              loading: () => const Center(
                child: PoppyMascot(size: 80, mood: PoppyMood.thinking),
              ),
              error: (e, _) => Center(child: Text('Something went wrong: $e')),
              data: (s) {
                if (s.isEmpty) return _AllLearned(onClose: _close);
                if (s.done) {
                  return SessionComplete(
                    session: s,
                    onDone: () => context.go(Routes.home),
                    onMore: () =>
                        ref.invalidate(learnSessionProvider(widget.topic)),
                  );
                }
                return _SessionBody(
                  session: s,
                  swipe: _swipe,
                  flip: _flip,
                  bloomKey: _bloomKey,
                  deckKey: _deckKey,
                  onClose: _close,
                  onSwiped: (dir) => _onSwiped(dir, s),
                  onGuess: (correct) => _session.recordGuess(correct: correct),
                );
              },
            ),
            for (final (id, from, to, color) in _petals)
              FlyingPetal(
                key: ValueKey(id),
                from: from,
                to: to,
                color: color,
                onDone: () {
                  if (mounted) {
                    setState(() => _petals.removeWhere((p) => p.$1 == id));
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({
    required this.session,
    required this.swipe,
    required this.flip,
    required this.bloomKey,
    required this.deckKey,
    required this.onClose,
    required this.onSwiped,
    required this.onGuess,
  });

  final SessionState session;
  final SwipeController swipe;
  final ValueNotifier<int> flip;
  final GlobalKey bloomKey;
  final GlobalKey deckKey;
  final VoidCallback onClose;
  final ValueChanged<SwipeDir> onSwiped;
  final ValueChanged<bool> onGuess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeDataProvider).value;
    final learned = session.learned.length;
    final isFirstCard = learned == 0 && session.againCount == 0;

    return Column(
      children: [
        // Top bar: close · progress · today's flower
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Close',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$learned of ${session.total} learned',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: learned / session.total),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => Stack(
                          children: [
                            Container(height: 8, color: AppColors.outline),
                            FractionallySizedBox(
                              widthFactor: v,
                              child: Container(
                                height: 8,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.bloomGradient,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PetalBloom(
                key: bloomKey,
                articles: home?.todayArticles ?? const [],
                goal: home?.dailyGoal ?? 10,
                size: 58,
              ),
            ],
          ),
        ),

        // Deck
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            child: SizedBox(
              key: deckKey,
              width: double.infinity,
              child: SwipeDeck(
                cards: session.queue,
                controller: swipe,
                hint: isFirstCard,
                onSwiped: onSwiped,
                cardBuilder: (card, isTop) => FlashCard(
                  word: card.word,
                  active: isTop,
                  flipSignal: isTop ? flip : null,
                  onGuess: isTop ? onGuess : null,
                ),
              ),
            ),
          ),
        ),

        // Actions
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundAction(
                label: 'Nochmal',
                semantic: 'Show again later',
                icon: Icons.replay_rounded,
                size: 64,
                background: AppColors.surface,
                foreground: AppColors.poppyText,
                border: AppColors.poppy,
                onTap: () => swipe.swipe(SwipeDir.left),
              ),
              _RoundAction(
                label: 'Flip',
                semantic: 'Flip card',
                icon: Icons.flip_rounded,
                size: 48,
                background: AppColors.surface,
                foreground: AppColors.ink,
                border: AppColors.outline,
                onTap: () => flip.value++,
              ),
              _RoundAction(
                label: 'Kann ich!',
                semantic: 'I know it',
                icon: Icons.check_rounded,
                size: 64,
                background: AppColors.ink,
                foreground: Colors.white,
                border: AppColors.ink,
                onTap: () => swipe.swipe(SwipeDir.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.label,
    required this.semantic,
    required this.icon,
    required this.size,
    required this.background,
    required this.foreground,
    required this.border,
    required this.onTap,
  });

  final String label;
  final String semantic;
  final IconData icon;
  final double size;
  final Color background;
  final Color foreground;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantic,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: background,
            shape: CircleBorder(side: BorderSide(color: border, width: 2)),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: size,
                child: Icon(icon, color: foreground, size: size * 0.45),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllLearned extends StatelessWidget {
  const _AllLearned({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const PoppyMascot(size: 100, mood: PoppyMood.excited),
          const SizedBox(height: 20),
          Text(
            'Wow, you learned them all! 🏆',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Every word in this set is in your garden. '
            'More words are coming soon!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onClose, child: const Text('Back')),
        ],
      ),
    );
  }
}
