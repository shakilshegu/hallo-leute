import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/state/meeting_controller.dart';

/// Shows the current café suggestion for a match and polls the backend for
/// the other person's response. No fake agreement — the meeting only opens
/// when the backend reports the suggestion `ACCEPTED`.
class CafeSuggestedScreen extends ConsumerStatefulWidget {
  final String matchId;
  const CafeSuggestedScreen({super.key, required this.matchId});

  @override
  ConsumerState<CafeSuggestedScreen> createState() =>
      _CafeSuggestedScreenState();
}

class _CafeSuggestedScreenState extends ConsumerState<CafeSuggestedScreen> {
  Timer? _poll;
  bool _busy = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(
      const Duration(seconds: 3),
      (_) => ref.invalidate(cafeSuggestionProvider(widget.matchId)),
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _onAccepted(String meetingId) async {
    if (_left) return;
    _left = true;
    _poll?.cancel();
    try {
      // Resolve + cache the meeting so the route guard lets us through.
      await ref.read(meetingDetailsProvider(meetingId).future);
    } catch (_) {}
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    context.pushReplacement(AppRoutes.meetingConfirmedPath(meetingId));
  }

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result =
          await ref.read(cafeApiProvider).acceptCafeSuggestion(widget.matchId);
      ref
          .read(meetingRepositoryProvider.notifier)
          .upsert(meetingFromDetails(result.meeting));
      ref.invalidate(cafeSuggestionProvider(widget.matchId));
      if (!mounted) return;
      _left = true;
      _poll?.cancel();
      HapticFeedback.heavyImpact();
      context
          .pushReplacement(AppRoutes.meetingConfirmedPath(result.meeting.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(cafeErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final suggestionAsync = ref.watch(cafeSuggestionProvider(widget.matchId));
    final partnerName = ref
            .watch(matchDetailsProvider(widget.matchId))
            .valueOrNull
            ?.user
            .name ??
        'your match';

    return Scaffold(
      backgroundColor: const Color(0xFF1E201F),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: suggestionAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => _messageBody(
                context,
                icon: Icons.error_outline,
                title: 'Couldn\'t load the suggestion',
                body: cafeErrorMessage(e),
                actionLabel: 'Back',
                onAction: () => context.pop(),
              ),
              data: (s) {
                if (s == null) {
                  return _messageBody(
                    context,
                    icon: Icons.local_cafe_outlined,
                    title: 'No café suggested yet',
                    body: 'Pick one to get the meeting confirmed.',
                    actionLabel: 'Choose a café',
                    onAction: () => context.pop(),
                  );
                }
                if (s.isAccepted && s.meetingId != null) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _onAccepted(s.meetingId!),
                  );
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  );
                }
                if (s.isDeclined) {
                  return _messageBody(
                    context,
                    icon: Icons.cancel_outlined,
                    title: 'Suggestion declined',
                    body: 'Try a different café or time.',
                    actionLabel: 'Choose a café',
                    onAction: () => context.pop(),
                  );
                }
                return _suggestionBody(
                  context,
                  s,
                  partnerName,
                  textTheme,
                  colorScheme,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _suggestionBody(
    BuildContext context,
    CafeSuggestion s,
    String partnerName,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final mine = s.suggestedBy.isMe;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8DF),
            shape: BoxShape.circle,
          ),
          child: Icon(mine ? Icons.send : Icons.local_cafe,
              color: const Color(0xFF2B4739), size: 32),
        ),
        const SizedBox(height: 24),
        Text(
          mine ? 'Café suggestion sent' : '$partnerName suggested a café',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (mine)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEBE6D8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'WAITING FOR ${partnerName.toUpperCase()}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.7),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // Café summary card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.cafe.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.cafe.address,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8DF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.calendar_today,
                          size: 14, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatSlotDateTime(s.date, s.startTime),
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            mine
                                ? 'Confirmed on your end'
                                : 'Accept to confirm the meeting',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        if (!mine)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2B4739),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Accept café'),
            ),
          ),
        if (!mine) const SizedBox(height: 16),

        InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
          child: Text(
            mine ? 'Change café or time' : 'Suggest another',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageBody(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 36, color: theme.colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
