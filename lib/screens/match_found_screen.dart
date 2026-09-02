import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/state/profile_controller.dart';
import 'package:poppylo/widgets/match_slot_format.dart';

class MatchFoundScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchFoundScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchFoundScreen> createState() => _MatchFoundScreenState();
}

class _MatchFoundScreenState extends ConsumerState<MatchFoundScreen> {
  bool _passing = false;

  Future<void> _pass() async {
    if (_passing) return;
    setState(() => _passing = true);
    try {
      await ref.read(matchingApiProvider).pass(widget.matchId);
      ref.invalidate(matchDetailsProvider(widget.matchId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match passed.')),
      );
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _passing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(matchingErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final matchAsync = ref.watch(matchDetailsProvider(widget.matchId));

    return PopScope(
      // Back must not return to the (now finished) searching screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F1EB),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: matchAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B3B2B)),
              ),
              error: (_, __) => _errorBody(context, textTheme, colorScheme),
              data: (match) => _body(context, match, textTheme, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorBody(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.link_off, size: 44, color: colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'Match no longer exists.',
          style: textTheme.titleMedium?.copyWith(color: colorScheme.primary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go(AppRoutes.home),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Text('Back home'),
          ),
        ),
      ],
    );
  }

  Widget _body(
    BuildContext context,
    MatchDetails match,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final myPhotoUrl = ref.watch(meProvider).valueOrNull?.profile?.photoUrl;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Text(
          "It's a match",
          style: textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'You and ${match.user.name} — ${match.score}% match.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.primary.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 140,
          width: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 0,
                child: _AvatarRing(imageUrl: myPhotoUrl),
              ),
              Positioned(
                right: 0,
                child: _AvatarRing(imageUrl: match.user.photoUrl),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCA928),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
                ),
                child:
                    const Icon(Icons.favorite, color: Colors.white, size: 24),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          formatMatchSlot(match).toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.6),
            letterSpacing: 2.0,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const Spacer(flex: 3),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _passing
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.matchDetailsPath(widget.matchId));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: Text(
              'View Match',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: TextButton(
            onPressed: _passing ? null : _pass,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _passing
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Pass',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _AvatarRing extends StatelessWidget {
  const _AvatarRing({this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
      ),
      child: CircleAvatar(
        radius: 56,
        backgroundColor: const Color(0xFFDDE5DE),
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
            ? NetworkImage(imageUrl!)
            : null,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? const Icon(Icons.person, size: 44, color: Color(0xFF1B3B2B))
            : null,
      ),
    );
  }
}
