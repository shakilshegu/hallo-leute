import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/widgets/match_slot_format.dart';

class MatchDetailScreen extends ConsumerStatefulWidget {
  final String matchId;
  const MatchDetailScreen({super.key, required this.matchId});

  @override
  ConsumerState<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends ConsumerState<MatchDetailScreen> {
  bool _busy = false;

  Future<void> _pass() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(matchingApiProvider).pass(widget.matchId);
      ref.invalidate(matchDetailsProvider(widget.matchId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match passed.')),
      );
      context.go(AppRoutes.home);
    } catch (e) {
      _reportError(e);
    }
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated =
          await ref.read(matchingApiProvider).accept(widget.matchId);
      ref.invalidate(matchDetailsProvider(widget.matchId));
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      if (updated.isConfirmed) {
        context.go(AppRoutes.matchConfirmedPath(widget.matchId));
      } else {
        context.pushReplacement(AppRoutes.matchWaitingPath(widget.matchId));
      }
    } catch (e) {
      _reportError(e);
    }
  }

  void _reportError(Object e) {
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(matchingErrorMessage(e))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final matchAsync = ref.watch(matchDetailsProvider(widget.matchId));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Coffee Meet',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: matchAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B3B2B)),
          ),
          error: (_, __) => _errorBody(context, textTheme, colorScheme),
          data: (match) => _content(context, match, textTheme, colorScheme),
        ),
      ),
    );
  }

  Widget _errorBody(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 44, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Match no longer exists.',
              style:
                  textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    MatchDetails match,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final user = match.user;
    final metaBits = [
      if (user.age != null) '${user.age} YRS',
      if ((user.job ?? '').isNotEmpty) user.job!.toUpperCase(),
      '${match.score}% MATCH',
    ].join(' · ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            'Someone who might be\nworth meeting.',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Main Profile Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.5,
                      child:
                          (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                              ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFFDDE5DE),
                                  child: const Icon(Icons.person,
                                      size: 72, color: Color(0xFF1B3B2B)),
                                ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        color: const Color(0xFFEBEBEB),
                        child: Text(
                          metaBits,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if ((user.bio ?? '').isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          user.bio!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (user.interests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'INTERESTS',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.5),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: user.interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDE5DE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                interest,
                                style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Why you matched
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why you matched',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                if (match.whyMatched.isEmpty)
                  _buildCheckItem(context, 'You share what matters for a meet')
                else
                  ...match.whyMatched
                      .map((reason) => _buildCheckItem(context, reason)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Proposed Time ticket
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'PROPOSED TIME',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatMatchDateTime(match),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F1EB),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Flex(
                            direction: Axis.horizontal,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(
                              (constraints.constrainWidth() / 8).floor(),
                              (index) => SizedBox(
                                width: 4,
                                height: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color:
                                          colorScheme.primary.withOpacity(0.2)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F1EB),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        'DURATION',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        formatMatchDuration(match),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _pass,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side:
                        BorderSide(color: colorScheme.primary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Pass',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1B3B2B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Accept match',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "You'll both need to accept before you can\nmessage.",
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              letterSpacing: 1.0,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
