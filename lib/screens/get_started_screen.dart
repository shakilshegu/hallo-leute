import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/models/country.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart';
import 'package:poppylo/state/auth_controller.dart';

class GetStartedScreen extends ConsumerStatefulWidget {
  final bool isNewUser;
  const GetStartedScreen({super.key, this.isNewUser = false});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  final TextEditingController _phoneController = TextEditingController();
  Country _selectedCountry = countries.first;
  bool _canProceed = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      setState(() {
        _canProceed = _phoneController.text.trim().length >= 10;
      });
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    if (!_canProceed || _isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    HapticFeedback.mediumImpact();

    // E.164 format required by Firebase.
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final e164Phone = '${_selectedCountry.dialCode}$digits';

    try {
      await ref.read(authControllerProvider.notifier).sendVerificationCode(
            e164Phone,
            isNewUser: widget.isNewUser,
          );
      if (!mounted) return;

      final auth = ref.read(authControllerProvider);
      if (auth.isSignedIn) {
        // Android silently auto-verified via SMS retrieval — no code to type.
        await _syncAndRoute();
      } else {
        context.push(AppRoutes.verify);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Mirrors [VerifyCodeScreen]'s post-verification routing for the rare
  /// Android auto-verify path: sync the backend user, route by its
  /// onboarding status, fall back to the welcome-screen choice if offline.
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
    if (widget.isNewUser) {
      auth.completeOnboardingStep(OnboardingStep.profile);
      context.push(AppRoutes.onboardProfile);
    } else {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _pickCountry() async {
    HapticFeedback.selectionClick();
    final theme = Theme.of(context);
    final selected = await showModalBottomSheet<Country>(
      context: context,
      backgroundColor: const Color(0xFFF3F1EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: countries.length,
          itemBuilder: (context, index) {
            final country = countries[index];
            return ListTile(
              leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
              title: Text(country.name),
              trailing: Text(
                country.dialCode,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () => Navigator.pop(context, country),
            );
          },
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _selectedCountry = selected);
    }
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
              const Spacer(flex: 2),

              Text(
                "Let's get you started",
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Phone Input Field
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Country Code
                    Semantics(
                      button: true,
                      label:
                          'Change country code, currently ${_selectedCountry.name} ${_selectedCountry.dialCode}',
                      child: InkWell(
                        onTap: _pickCountry,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Text(
                                '${_selectedCountry.isoCode} ${_selectedCountry.dialCode}',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 24,
                      color: colorScheme.primary.withOpacity(0.2),
                    ),

                    // Phone Number Input
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        onSubmitted: (_) => _handleContinue(),
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: '000 000 0000',
                          hintStyle: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.primary.withOpacity(0.3),
                            fontWeight: FontWeight.w500,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: textTheme.bodySmall?.copyWith(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),

              // Continue Button
              AnimatedOpacity(
                opacity: _canProceed || _isLoading ? 1.0 : 0.5,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed:
                        (_canProceed && !_isLoading) ? _handleContinue : null,
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

              const SizedBox(height: 16),

              // Footer text
              Text(
                "WE'LL TEXT YOU A CODE",
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
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
