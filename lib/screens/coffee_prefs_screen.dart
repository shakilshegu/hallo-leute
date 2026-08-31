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
import 'package:poppylo/state/search_controller.dart';
import 'package:poppylo/widgets/onboarding_widgets.dart';

/// Onboarding screen 3 of 3 — the practical meetup preferences. Everything
/// has a sensible default so "Start Coffee Meet" is live on arrival.
class CoffeePrefsScreen extends ConsumerStatefulWidget {
  const CoffeePrefsScreen({super.key});

  @override
  ConsumerState<CoffeePrefsScreen> createState() => _CoffeePrefsScreenState();
}

class _CoffeePrefsScreenState extends ConsumerState<CoffeePrefsScreen> {
  static const _distances = [2, 5, 10];
  static const _lengths = ['30 min', '45 min', '60 min'];

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickWhen(String option) async {
    HapticFeedback.selectionClick();
    if (option != 'Choose a date') {
      ref.read(onboardingControllerProvider.notifier).setWhen(option);
      return;
    }

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ref.read(onboardingControllerProvider).chosenDate ??
          now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Pick a day for coffee',
    );
    if (picked != null) {
      ref
          .read(onboardingControllerProvider.notifier)
          .setWhen('Choose a date', chosenDate: picked);
    }
  }

  Future<void> _startCoffeeMeet() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    final data = ref.read(onboardingControllerProvider);

    try {
      await ref.read(onboardingApiProvider).setPreferences(
        minAge: OnboardingProfile.defaultMinAge,
        maxAge: OnboardingProfile.defaultMaxAge,
        maxDistanceKm: data.distanceKm,
        conversationStyles: [data.conversationStyleApiValue],
      );
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

    ref.read(searchControllerProvider.notifier).start(data.toMeetRequest());
    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.done);
    context.go(AppRoutes.coffeeReady);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final data = ref.watch(onboardingControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: const OnboardingAppBar(step: 3),
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
                      title: 'Make your coffee meetup work for you',
                      subtitle: 'Set your basic meetup preferences.',
                    ),
                    const SizedBox(height: 32),

                    // --- Section 1: distance ---
                    const OnboardingSectionLabel('DISTANCE'),
                    const SizedBox(height: 6),
                    Text(
                      'How far are you willing to travel?',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OnboardingSegmentedRow(
                      options: [for (final d in _distances) '$d km'],
                      selected: '${data.distanceKm} km',
                      onSelected: (v) => ref
                          .read(onboardingControllerProvider.notifier)
                          .setDistance(int.parse(v.split(' ').first)),
                    ),
                    const SizedBox(height: 32),

                    // --- Section 2: meeting length ---
                    const OnboardingSectionLabel('MEETING LENGTH'),
                    const SizedBox(height: 6),
                    Text(
                      'How long would you like to meet?',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    OnboardingSegmentedRow(
                      options: _lengths,
                      selected: data.meetingLength,
                      onSelected: (v) => ref
                          .read(onboardingControllerProvider.notifier)
                          .setMeetingLength(v),
                    ),
                    const SizedBox(height: 32),

                    // --- Section 3: when ---
                    const OnboardingSectionLabel('WHEN'),
                    const SizedBox(height: 6),
                    Text(
                      'When would you usually like to meet?',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _WhenRow(
                      selected: data.when,
                      dateLabel: data.timeLabel,
                      onSelected: _pickWhen,
                    ),
                  ],
                ),
              ),
            ),
            OnboardingErrorBanner(message: _errorMessage),
            OnboardingPrimaryButton(
              label: 'Start Coffee Meet',
              enabled: true,
              loading: _isLoading,
              onPressed: _startCoffeeMeet,
              trailingIcon: Icons.local_cafe_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _WhenRow extends StatelessWidget {
  const _WhenRow({
    required this.selected,
    required this.dateLabel,
    required this.onSelected,
  });

  final String selected;
  final String dateLabel;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    const options = ['Today', 'Tomorrow', 'Choose a date'];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == options.length - 1 ? 0 : 12),
              child: Semantics(
                button: true,
                selected: options[i] == selected,
                label: options[i],
                child: GestureDetector(
                  onTap: () => onSelected(options[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 48,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: options[i] == selected
                          ? colorScheme.primary
                          : colorScheme.primary.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: options[i] == selected
                            ? colorScheme.primary
                            : colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (options[i] == 'Choose a date') ...[
                          Icon(
                            Icons.calendar_today,
                            size: 13,
                            color: options[i] == selected
                                ? colorScheme.onPrimary
                                : colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            options[i] == 'Choose a date' &&
                                    selected == 'Choose a date'
                                ? dateLabel
                                : options[i] == 'Choose a date'
                                    ? 'Date'
                                    : options[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: options[i] == selected
                                  ? colorScheme.onPrimary
                                  : colorScheme.primary,
                              fontWeight: options[i] == selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
