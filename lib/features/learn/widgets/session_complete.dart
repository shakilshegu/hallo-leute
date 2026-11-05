import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/confetti.dart';
import '../../../widgets/fun_icon.dart';
import '../../../widgets/poppy_mascot.dart';
import '../../home/widgets/streak_pot.dart';
import '../learn_session.dart';

/// End of a flashcard session: Poppy celebrates and shows what was learned.
class SessionComplete extends ConsumerStatefulWidget {
  const SessionComplete({
    super.key,
    required this.session,
    required this.onMore,
    required this.onDone,
  });

  final SessionState session;
  final VoidCallback onMore;
  final VoidCallback onDone;

  @override
  ConsumerState<SessionComplete> createState() => _SessionCompleteState();
}

class _SessionCompleteState extends ConsumerState<SessionComplete> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final home = ref.watch(homeDataProvider).value;
    final streak = home?.streak ?? 0;
    final text = Theme.of(context).textTheme;
    final perfect = s.guessTotal > 0 && s.guessCorrect == s.guessTotal;

    return Stack(
      children: [
        const Positioned.fill(child: ConfettiBurst(originY: 0.12)),
        ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          children: [
            const Center(child: PoppyMascot(size: 110, mood: PoppyMood.excited))
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 18),
            Text(
              'Super gemacht! 🎉',
              textAlign: TextAlign.center,
              style: text.displayMedium?.copyWith(fontSize: 30),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
            const SizedBox(height: 6),
            Text(
              perfect
                  ? 'Well done! Every article right. Wow!'
                  : 'Well done! Your garden just grew.',
              textAlign: TextAlign.center,
              style: text.bodyLarge?.copyWith(color: AppColors.muted),
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: const FunIcon(
                      '🌸',
                      color: AppColors.poppy,
                      size: 44,
                      motion: FunMotion.tada,
                    ),
                    value: '+${s.learned.length}',
                    label: s.learned.length == 1 ? 'word' : 'words',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: const FunIcon(
                      '🎯',
                      color: AppColors.lavender,
                      size: 44,
                      motion: FunMotion.pulse,
                    ),
                    value: s.guessTotal == 0
                        ? '–'
                        : '${s.guessCorrect}/${s.guessTotal}',
                    label: 'articles',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    icon: StreakPot(stage: StreakStage.of(streak), size: 44),
                    value: '$streak',
                    label: streak == 1 ? 'Tag' : 'Tage',
                  ),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15),
            const SizedBox(height: 22),
            Text('Neue Wörter · New words', style: text.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (i, w) in s.learned.indexed)
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: (w.article?.color ?? AppColors.outline)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: '${w.emoji} '),
                              if (w.article != null)
                                TextSpan(
                                  text: '${w.article!.name} ',
                                  style: TextStyle(color: w.article!.textColor),
                                ),
                              TextSpan(text: w.german),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: (500 + 60 * i).ms)
                      .scaleXY(
                        begin: 0.8,
                        delay: (500 + 60 * i).ms,
                        curve: Curves.easeOutBack,
                      ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: widget.onDone,
              child: const Text('Zurück zu Heute · Back home'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: widget.onMore,
              child: const Text('Learn 5 more 🌱'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final Widget icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        children: [
          icon,
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
