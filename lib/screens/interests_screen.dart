import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  final List<String> _allInterests = [
    'Travel',
    'Fitness',
    'Movies',
    'Music',
    'Books',
    'Food',
    'Startups',
    'Technology',
    'Design',
    'Photography',
    'Sports',
    'Gaming',
    'Art',
    'Business'
  ];

  final Set<String> _selectedInterests = {};
  bool _isLoading = false;

  void _toggleInterest(String interest) {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 7) {
          _selectedInterests.add(interest);
        } else {
          // Could show a snackbar here that max 7 is allowed
          HapticFeedback.heavyImpact();
        }
      }
    });
  }

  void _handleContinue() async {
    if (_selectedInterests.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.preferences);
    context.push(AppRoutes.onboardPreferences);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'What do you enjoy?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Pick a few things you'd love to talk about. (Max 7)",
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 16.0,
                      children: _allInterests.map((interest) {
                        final isSelected =
                            _selectedInterests.contains(interest);
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: interest,
                          child: GestureDetector(
                            onTap: () => _toggleInterest(interest),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    interest,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: isSelected
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.check,
                                      size: 14,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_selectedInterests.length} OF 7',
                        style: textTheme.labelSmall?.copyWith(
                          color: _selectedInterests.length == 7
                              ? colorScheme.primary
                              : colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity:
                    _selectedInterests.isNotEmpty || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedInterests.isNotEmpty && !_isLoading)
                        ? _handleContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                      disabledBackgroundColor:
                          colorScheme.primary.withOpacity(0.5),
                      disabledForegroundColor:
                          colorScheme.onPrimary.withOpacity(0.8),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            'Continue',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
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
}
