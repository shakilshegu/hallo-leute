import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';

/// Email/password login for a returning user. New users go through
/// [GetStartedScreen]'s phone/OTP flow instead — see /login vs /login/email.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _canProceed = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    void updateState() {
      setState(() {
        _canProceed = _emailController.text.trim().isNotEmpty &&
            _passwordController.text.isNotEmpty;
        // Clear error when user types
        if (_emailError != null) _emailError = null;
      });
    }

    _emailController.addListener(updateState);
    _passwordController.addListener(updateState);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_canProceed || _isLoading) return;

    final email = _emailController.text.trim();
    final emailValid = RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email);

    if (!emailValid) {
      setState(() {
        _emailError = 'Please enter a valid email address';
      });
      HapticFeedback.heavyImpact(); // Error feedback
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    ref.read(authControllerProvider.notifier).signInExistingUser();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Light cream from design
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
                "Welcome back",
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Log in to continue your journey.",
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 48),

              // Email Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: _emailError != null
                          ? Colors.red.withOpacity(0.05)
                          : colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: _emailError != null
                          ? Border.all(color: Colors.red.withOpacity(0.5))
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_passwordFocus);
                        },
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary.withOpacity(0.3),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.email_outlined,
                              color: _emailError != null
                                  ? Colors.red.withOpacity(0.5)
                                  : colorScheme.primary.withOpacity(0.5)),
                        ),
                      ),
                    ),
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        _emailError!,
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 16),

              // Password Input Field
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _handleLogin(),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Password',
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.3),
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      icon: Icon(Icons.lock_outline,
                          color: colorScheme.primary.withOpacity(0.5)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colorScheme.primary.withOpacity(0.5),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot password link
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  button: true,
                  label: 'Forgot password',
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                          },
                    child: Text(
                      'Forgot password?',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Continue Button
              AnimatedOpacity(
                opacity: _canProceed || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_canProceed && !_isLoading) ? _handleLogin : null,
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
                            'Log in',
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
