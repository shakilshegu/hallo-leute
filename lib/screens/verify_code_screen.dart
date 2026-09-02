import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';
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
  String? _errorMessage;

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
    // Bring up the keyboard once the screen has settled.
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

  /// Re-request the code. Throws on failure so the resend button doesn't
  /// restart its cooldown.
  Future<void> _resend() async {
    HapticFeedback.lightImpact();
    setState(() => _errorMessage = null);
    try {
      await ref.read(authControllerProvider.notifier).resendCode();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = e.toString().replaceFirst('Exception: ', ''));
      }
      rethrow;
    }
    if (!mounted) return;
    _codeController.clear();
    _focusNode.requestFocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('New code sent.')));
  }

  void _handleVerify() async {
    if (!_canProceed || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref
          .read(authControllerProvider.notifier)
          .confirmVerificationCode(_codeController.text);
      if (!mounted) return;

      await _syncAndRoute();
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _codeController.clear();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Creates/finds the backend user and routes by its authoritative
  /// onboarding status. If the API can't be reached, fall back to the
  /// welcome-screen choice so a flaky network doesn't strand the user —
  /// the onboarding screens will retry the real work.
  Future<void> _syncAndRoute() async {
    final auth = ref.read(authControllerProvider.notifier);
    try {
      final sync = await ref.read(onboardingApiProvider).syncUser();
      final notice = postAuthNotice(
        intendedSignup: ref.read(authControllerProvider).isNewUser,
        isNewUser: sync.isNewUser,
        onboardingCompleted: sync.onboardingCompleted,
      );
      auth.applyBackendSync(onboardingCompleted: sync.onboardingCompleted);
      if (!mounted) return;
      if (notice != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(notice)));
      }
      if (sync.onboardingCompleted) {
        context.go(AppRoutes.home);
      } else {
        context.push(AppRoutes.onboardProfile);
      }
      return;
    } on ApiException {
      // Offline-friendly fallback below.
    }

    if (!mounted) return;
    if (ref.read(authControllerProvider).isNewUser) {
      auth.completeOnboardingStep(OnboardingStep.profile);
      context.push(AppRoutes.onboardProfile);
    } else {
      // `go`, not `push`: the guard redirects returning users into the
      // bottom-nav shell, which only mounts correctly when the whole stack
      // is recomputed.
      context.go(AppRoutes.home);
    }
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
                'We sent a 6-digit code to\n${ref.watch(authControllerProvider).pendingPhoneNumber ?? ''}',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // 6-digit code input: the boxes are just a visual; a real,
              // interactive (but transparent) TextField sits on top and
              // captures every tap and keystroke.
              Stack(
                alignment: Alignment.center,
                children: [
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
                  Positioned.fill(
                    child: TextField(
                      controller: _codeController,
                      focusNode: _focusNode,
                      enabled: !_isLoading,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      showCursor: false,
                      enableInteractiveSelection: false,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      cursorColor: Colors.transparent,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        fillColor: Colors.transparent,
                        filled: true,
                      ),
                    ),
                  ),
                ],
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],
              const SizedBox(height: 32),

              Center(
                child: _ResendCode(
                  enabled: !_isLoading,
                  onResend: _resend,
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

/// "Resend Code" with a 30-second cooldown. Kept as its own stateful widget so
/// its per-second timer only rebuilds this button — not the parent screen and
/// its text field, which would fight the user's typing.
class _ResendCode extends StatefulWidget {
  const _ResendCode({required this.onResend, required this.enabled});

  /// Should throw on failure so the cooldown is not restarted.
  final Future<void> Function() onResend;
  final bool enabled;

  @override
  State<_ResendCode> createState() => _ResendCodeState();
}

class _ResendCodeState extends State<_ResendCode> {
  static const _cooldown = 30;
  int _left = _cooldown;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _left = _cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _tap() async {
    if (_left > 0 || _busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      await widget.onResend();
      if (mounted) _start();
    } catch (_) {
      // onResend surfaced the error; leave the button active for a retry.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final base = Theme.of(context).textTheme.labelSmall;
    final onCooldown = _left > 0;
    return Semantics(
      button: true,
      label: 'Resend code',
      child: TextButton(
        onPressed: (onCooldown || _busy || !widget.enabled) ? null : _tap,
        child: _busy
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                onCooldown ? 'Resend code in ${_left}s' : 'Resend Code',
                style: base?.copyWith(
                  color: onCooldown ? primary.withOpacity(0.4) : primary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
