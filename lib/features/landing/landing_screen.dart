import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/reveal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../data/auth/auth_service.dart';
import '../home/home_screen.dart';
import '../onboarding/onboarding_flow.dart';
import '../profile/account_card.dart';
import 'widgets/floating_words.dart';
import 'widgets/pan_logo.dart';

/// First screen of the app: brand, promise and a single CTA.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, this.onGetStarted, this.onSignIn});

  final VoidCallback? onGetStarted;
  final VoidCallback? onSignIn;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _entrance.value = 1;
      _ambient.stop();
    } else if (!_started) {
      _entrance.forward();
      _ambient.repeat();
    }
    _started = true;
  }

  @override
  void dispose() {
    _entrance.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Returning learner: sign in, then open Home with the account's
  /// profile, or onboarding when the account has none yet.
  Future<void> _signIn() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null) return _comingSoon('Sign in');
    final navigator = Navigator.of(context);
    if (!await showSignInSheet(context, auth)) return;
    final profile = await auth.progress.loadProfile();
    if (profile != null) {
      navigator.pushAndRemoveUntil(HomeScreen.route(profile), (_) => false);
    } else {
      navigator.push(OnboardingFlow.route());
    }
  }

  void _comingSoon(String what) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$what – coming next!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: FloatingWords(
                ambient: _ambient,
                reveal: _interval(0.5, 1.0),
              ),
            ),
            SafeArea(
              child: Center(
                // Max width sits outside the scroll view so IntrinsicHeight
                // measures text at the real width.
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(child: _content(constraints)),
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

  Widget _content(BoxConstraints constraints) {
    final diameter = math.min(
      (constraints.maxWidth - 48) / PanLogo.widthFactor,
      math.min(constraints.maxHeight * 0.27, 250.0),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Reveal(animation: _interval(0.0, 0.3), child: const _LevelPill()),
          const Spacer(flex: 2),
          PanLogo(diameter: diameter, entrance: _entrance, ambient: _ambient),
          const Spacer(flex: 2),
          Reveal(
            animation: _interval(0.52, 0.8),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'German,\n'),
                  TextSpan(
                    text: 'made simple.',
                    style: AppText.display(
                      34,
                      color: AppColors.mustard,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppText.display(34, color: AppColors.cream, height: 1.1),
            ),
          ),
          const SizedBox(height: 14),
          Reveal(
            animation: _interval(0.6, 0.86),
            child: Text(
              'Learn everyday German words and phrases in just a few '
              'minutes a day – for study, work and life in Germany.',
              textAlign: TextAlign.center,
              style: AppText.body(
                15.5,
                color: AppColors.creamMuted,
                height: 1.5,
              ),
            ),
          ),
          const Spacer(flex: 3),
          const SizedBox(height: 24),
          Reveal(
            animation: _interval(0.78, 1.0),
            child: PrimaryButton(
              label: "Los geht's",
              onPressed:
                  widget.onGetStarted ??
                  () => Navigator.of(context).push(OnboardingFlow.route()),
            ),
          ),
          const SizedBox(height: 6),
          Reveal(
            animation: _interval(0.82, 1.0),
            child: TextButton(
              onPressed: widget.onSignIn ?? _signIn,
              style: TextButton.styleFrom(foregroundColor: AppColors.cream),
              child: Text.rich(
                TextSpan(
                  text: 'Already learning? ',
                  style: AppText.body(14.5, color: AppColors.creamMuted),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: AppText.body(
                        14.5,
                        weight: FontWeight.w800,
                        color: AppColors.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
    parent: _entrance,
    curve: Interval(begin, end, curve: Curves.easeOutCubic),
  );
}

class _LevelPill extends StatelessWidget {
  const _LevelPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.cream.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.mustard,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Deutsch lernen · A1 – B2',
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                12.5,
                weight: FontWeight.w700,
                color: AppColors.cream,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
