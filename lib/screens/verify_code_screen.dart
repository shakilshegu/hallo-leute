import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canProceed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() {
      setState(() {
        _canProceed = _codeController.text.length == 6;
      });
      // Auto-submit when 6 digits are entered
      if (_codeController.text.length == 6 && !_isLoading) {
        _handleVerify();
      }
    });
    // Auto focus the hidden text field
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleVerify() async {
    if (!_canProceed || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    ref.read(authControllerProvider.notifier).verifyCode();
    ref
        .read(authControllerProvider.notifier)
        .completeOnboardingStep(OnboardingStep.profile);
    context.push(AppRoutes.onboardProfile);

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              Text(
                'Enter your code',
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a 6-digit code to\n+1 ${ref.watch(authControllerProvider).pendingPhoneNumber ?? ''}',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // 6-digit Code Input
              GestureDetector(
                onTap: () {
                  if (!_isLoading) _focusNode.requestFocus();
                },
                child: AbsorbPointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Hidden TextField to capture input
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _codeController,
                          focusNode: _focusNode,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          autofillHints: const [AutofillHints.oneTimeCode],
                        ),
                      ),
                      // UI representation of the 6 digits
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final text = _codeController.text;
                          final char = index < text.length ? text[index] : '';
                          final isActive = text.length == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 56,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isActive && !_isLoading
                                    ? colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              char,
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: Semantics(
                  button: true,
                  label: 'Resend code',
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                          },
                    child: Text(
                      'Resend Code',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Verify Button
              AnimatedOpacity(
                opacity: _canProceed || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_canProceed && !_isLoading) ? _handleVerify : null,
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
                            'Verify',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
