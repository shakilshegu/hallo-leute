import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/models/onboarding_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/onboarding_controller.dart';
import 'package:poppylo/widgets/onboarding_widgets.dart';

/// Onboarding screen 2 of 3 — the kind of person and conversation the user
/// wants over coffee. Progressive sections, single scroll.
class ConversationPrefsScreen extends ConsumerStatefulWidget {
  const ConversationPrefsScreen({super.key});

  @override
  ConsumerState<ConversationPrefsScreen> createState() =>
      _ConversationPrefsScreenState();
}

class _ConversationPrefsScreenState
    extends ConsumerState<ConversationPrefsScreen> {
  static const _purposes = <String, IconData>{
    'Make friends': Icons.people_outline,
    'Networking': Icons.work_outline,
    'Shared interests': Icons.extension_outlined,
    'Dating': Icons.favorite_border,
    'Good conversation': Icons.chat_bubble_outline,
  };

  static const _interests = [
    'Travel',
    'Food',
    'Technology',
    'Startups',
    'Music',
    'Movies',
    'Fitness',
    'Books',
    'Design',
    'Photography',
    'Sports',
    'Gaming',
  ];

  static const _styles = ['Casual', 'Deep', 'Professional', 'Playful'];

  bool _isLoading = false;
  String? _errorMessage;

  void _selectPurpose(String purpose) {
    HapticFeedback.selectionClick();
    ref.read(onboardingControllerProvider.notifier).setPurpose(purpose);
  }

  void _toggleInterest(String interest) {
    final selected = ref.read(onboardingControllerProvider).interests;
    if (!selected.contains(interest) &&
        selected.length >= OnboardingProfile.maxInterests) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Pick up to 7 — tap one to swap.'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }
    HapticFeedback.lightImpact();
    ref.read(onboardingControllerProvider.notifier).toggleInterest(interest);
  }

  void _selectStyle(String style) {
    HapticFeedback.selectionClick();
    ref.read(onboardingControllerProvider.notifier).setConversationStyle(style);
  }

  Future<void> _handleContinue() async {
    final data = ref.read(onboardingControllerProvider);
    final canProceed = data.purpose != null &&
        data.interests.isNotEmpty &&
        data.conversationStyle != null;
    if (!canProceed || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final api = ref.read(onboardingApiProvider);
      await api.setInterests(data.interestIds);
      await api.setPurpose(data.purposeApiValue!);
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    }
    if (!mounted) return;

    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.coffee);
    context.push(AppRoutes.onboardCoffee);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final data = ref.watch(onboardingControllerProvider);
    final canProceed = data.purpose != null &&
        data.interests.isNotEmpty &&
        data.conversationStyle != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: const OnboardingAppBar(step: 2),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingHeader(
                      title:
                          'What kind of coffee conversation are you looking for?',
                      subtitle:
                          'Choose what feels right. You can change this anytime.',
                    ),
                    const SizedBox(height: 28),

                    // --- Section 1: purpose ---
                    const OnboardingSectionLabel('PURPOSE'),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.35,
                      children: [
                        for (final entry in _purposes.entries)
                          _PurposeCard(
                            label: entry.key,
                            icon: entry.value,
                            selected: data.purpose == entry.key,
                            onTap: () => _selectPurpose(entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- Section 2: interests ---
                    OnboardingSectionLabel(
                      'WHAT ARE YOU INTO?',
                      trailing: Text(
                        '${data.interests.length} / ${OnboardingProfile.maxInterests}',
                        style: textTheme.labelSmall?.copyWith(
                          color: data.interests.length ==
                                  OnboardingProfile.maxInterests
                              ? colorScheme.primary
                              : colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        for (final interest in _interests)
                          OnboardingChip(
                            label: interest,
                            selected: data.interests.contains(interest),
                            onTap: () => _toggleInterest(interest),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- Section 3: conversation style ---
                    const OnboardingSectionLabel('HOW DO YOU LIKE TO TALK?'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 12,
                      children: [
                        for (final style in _styles)
                          OnboardingChip(
                            label: style,
                            selected: data.conversationStyle == style,
                            onTap: () => _selectStyle(style),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            OnboardingErrorBanner(message: _errorMessage),
            OnboardingPrimaryButton(
              label: 'Continue',
              enabled: canProceed,
              loading: _isLoading,
              onPressed: _handleContinue,
              trailingIcon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurposeCard extends StatelessWidget {
  const _PurposeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withOpacity(0.15)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary, size: 28),
              const Spacer(),
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
