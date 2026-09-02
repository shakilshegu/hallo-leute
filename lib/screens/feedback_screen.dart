import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/feedback_models.dart';
import 'package:poppylo/services/api_client.dart' show ApiException;
import 'package:poppylo/state/cafe_controller.dart'
    show allMeetingsProvider, meetingDetailsProvider, upcomingMeetingsProvider;
import 'package:poppylo/state/feedback_controller.dart';
import 'package:poppylo/state/meeting_controller.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  final String meetingId;
  const FeedbackScreen({super.key, required this.meetingId});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  int _rating = 0;
  String? _conversationFeel;
  String? _meetAgain;
  final Set<String> _stoodOut = {};
  bool _submitting = false;

  bool get _canSubmit =>
      _rating > 0 &&
      _conversationFeel != null &&
      _meetAgain != null &&
      !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    try {
      final result = await ref.read(feedbackApiProvider).submit(
            widget.meetingId,
            rating: _rating,
            conversationFeeling:
                kConversationFeelingToApi[_conversationFeel] ?? 'OKAY',
            wouldMeetAgain: wouldMeetAgainFromLabel(_meetAgain),
            tags: _stoodOut
                .map((label) => kFeedbackTagToApi[label])
                .whereType<String>()
                .toList(),
          );

      // Keep the local caches the meeting screens + route guard read in sync.
      ref.read(meetingRepositoryProvider.notifier).submitFeedback(
            widget.meetingId,
          );
      _invalidateMeetingCaches();

      if (!mounted) return;
      _goNext(result.mutualConnectionCreated, result.connectionId);
    } catch (e) {
      if (!mounted) return;
      // A 409 means it's already recorded — treat it as done, not an error to
      // retry.
      if (e is ApiException && e.statusCode == 409) {
        ref.read(meetingRepositoryProvider.notifier).submitFeedback(
              widget.meetingId,
            );
        _invalidateMeetingCaches();
        _goNext(false, null);
        return;
      }
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedbackErrorMessage(e))),
      );
    }
  }

  /// After feedback the meeting is COMPLETED server-side — refresh every
  /// surface that shows its status.
  void _invalidateMeetingCaches() {
    ref.invalidate(feedbackStatusProvider(widget.meetingId));
    ref.invalidate(meetingDetailsProvider(widget.meetingId));
    ref.invalidate(upcomingMeetingsProvider);
    ref.invalidate(allMeetingsProvider);
  }

  void _goNext(bool mutualConnectionCreated, String? connectionId) {
    if (mutualConnectionCreated) {
      context.pushReplacement(
        AppRoutes.mutualConnectionPath(widget.meetingId),
        extra: connectionId,
      );
    } else {
      context.pushReplacement(AppRoutes.feedbackSentPath(widget.meetingId));
    }
  }

  final List<String> _feelOptions = ['GREAT', 'GOOD', 'OKAY', 'NOT GREAT'];
  final List<String> _meetOptions = ['YES', 'MAYBE', 'NO'];
  final List<String> _stoodOutOptions = [
    'FRIENDLY',
    'INTERESTING',
    'EASY TO TALK TO',
    'GREAT CONVERSATION',
    'NOT A GOOD FIT'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final partner = ref
        .watch(meetingDetailsProvider(widget.meetingId))
        .valueOrNull
        ?.partner;
    final partnerName = partner?.name ?? 'them';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF3F1EB), // Warm beige background from mockup
      body: SafeArea(
        child: Column(
          children: [
            // Header with Close button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colorScheme.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.pop();
                    },
                  ),
                  Text(
                    'FEEDBACK',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for centering
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 16),
                  // Profile Image
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: const Color(0xFFE6EBE6),
                      backgroundImage: (partner?.profileImage != null &&
                              partner!.profileImage!.isNotEmpty)
                          ? NetworkImage(partner.profileImage!)
                          : null,
                      child: (partner?.profileImage == null ||
                              partner!.profileImage!.isEmpty)
                          ? Icon(Icons.person,
                              color: colorScheme.primary, size: 32)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // How was your coffee?
                  Text(
                    'How was your coffee?',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFE6A316), // Gold color
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),

                  // Question 1
                  _buildQuestionLabel('01', 'How did the conversation feel?',
                      textTheme, colorScheme),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _feelOptions
                        .map((option) => _buildSingleSelectPill(
                              label: option,
                              isSelected: _conversationFeel == option,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _conversationFeel = option);
                              },
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),

                  // Question 2
                  _buildQuestionLabel(
                      '02',
                      'Would you meet $partnerName again?',
                      textTheme,
                      colorScheme),
                  const SizedBox(height: 16),
                  Row(
                    children: _meetOptions
                        .map((option) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: _buildSingleSelectPill(
                                  label: option,
                                  isSelected: _meetAgain == option,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _meetAgain = option);
                                  },
                                  colorScheme: colorScheme,
                                  textTheme: textTheme,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),

                  // Question 3
                  _buildQuestionLabel(
                      '03', 'What stood out?', textTheme, colorScheme,
                      isOptional: true),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _stoodOutOptions
                        .map((option) => _buildMultiSelectPill(
                              label: option,
                              isSelected: _stoodOut.contains(option),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  if (_stoodOut.contains(option)) {
                                    _stoodOut.remove(option);
                                  } else {
                                    _stoodOut.add(option);
                                  }
                                });
                              },
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),

            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B), // Dark green
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFF1B3B2B).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'SUBMIT FEEDBACK',
                          style: textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionLabel(String number, String question,
      TextTheme textTheme, ColorScheme colorScheme,
      {bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: colorScheme.primary.withOpacity(0.1)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOptional)
              Text(
                '(Optional)',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleSelectPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3B2B) : const Color(0xFFE6EBE6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected
                ? Colors.white
                : colorScheme.primary.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B3B2B)
                : colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected
                ? const Color(0xFF1B3B2B)
                : colorScheme.primary.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
