import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';

class PurposeScreen extends ConsumerStatefulWidget {
  const PurposeScreen({super.key});

  @override
  ConsumerState<PurposeScreen> createState() => _PurposeScreenState();
}

class _PurposeScreenState extends ConsumerState<PurposeScreen> {
  String? _selectedPurpose;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _purposes = [
    {'title': 'Make new friends', 'icon': Icons.people_outline},
    {'title': 'Networking', 'icon': Icons.work_outline},
    {'title': 'Meet people in my city', 'icon': Icons.location_city_outlined},
    {'title': 'Shared interests', 'icon': Icons.extension_outlined},
    {'title': 'Dating', 'icon': Icons.favorite_border},
    {'title': 'Just a good conversation', 'icon': Icons.chat_bubble_outline},
  ];

  void _handleContinue() async {
    if (_selectedPurpose == null || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.notifications);
    context.push(AppRoutes.onboardNotifications);
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
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'What brings you here?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _purposes.length,
                      itemBuilder: (context, index) {
                        final purpose = _purposes[index];
                        final isSelected = _selectedPurpose == purpose['title'];

                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: purpose['title'] as String,
                          child: GestureDetector(
                            onTap: _isLoading
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      _selectedPurpose = purpose['title'];
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primary.withOpacity(0.15)
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    purpose['icon'] as IconData,
                                    color: colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    purpose['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'YOU CAN CHANGE THIS ANYTIME',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
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
                opacity: _selectedPurpose != null || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedPurpose != null && !_isLoading)
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
