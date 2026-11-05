import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/fun_icon.dart';
import '../../widgets/poppy_mascot.dart';

/// Friendly placeholder for tabs that are built next.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({
    required this.german,
    required this.english,
    required this.poppy,
    this.child,
  });

  final String german;
  final String english;
  final String poppy;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Text(german, style: Theme.of(context).textTheme.displayMedium),
            Text(
              english,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 32),
            PoppySays(text: poppy, mood: PoppyMood.thinking),
            if (child != null) ...[const SizedBox(height: 28), child!],
          ],
        ),
      ),
    );
  }
}

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ComingSoon(
    german: 'Wiederholen',
    english: 'Review',
    poppy: 'Your review garden opens soon. I’ll keep your words fresh!',
  );
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;
    final text = Theme.of(context).textTheme;

    return _ComingSoon(
      german: 'Ich',
      english: 'Me',
      poppy: 'Your profile and settings are coming soon.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    FunIcon(
                      profile.reason.emoji,
                      color: AppColors.lavender,
                      motion: FunMotion.wobble,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name ?? 'Learner',
                            style: text.titleLarge,
                          ),
                          Text(
                            '${profile.reason.title} · ${profile.level.code} · '
                            '${profile.dailyGoal} words a day',
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (kDebugMode) ...[
            const SizedBox(height: 24),
            Text(
              'Developer tools (debug builds only)',
              style: text.titleMedium,
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                await ref.read(databaseProvider).debugSeedProgress();
                if (context.mounted) context.go(Routes.home);
              },
              child: const Text('🌱 Fill garden with sample progress'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                await ref.read(databaseProvider).clearProfile();
                ref.invalidate(profileProvider);
                if (context.mounted) context.go(Routes.welcome);
              },
              child: const Text('↺ Reset onboarding'),
            ),
          ],
        ],
      ),
    );
  }
}
