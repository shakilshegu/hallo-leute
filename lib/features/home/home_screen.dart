import 'package:flutter/material.dart';

import '../../data/vocabulary.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/app_nav_bar.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_data.dart';
import '../profile/profile_tab.dart';
import '../words/words_tab.dart';
import '../practice/practice_tab.dart';
import '../topics/topic_screen.dart';
import 'home_tab.dart';

/// Main shell after onboarding: Home · Words · Profile with a floating nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile, this.now});

  final OnboardingData profile;

  /// Clock override for tests.
  final DateTime Function()? now;

  static Route<void> route(OnboardingData profile) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => HomeScreen(profile: profile),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _home = 0, _practice = 1, _words = 2, _profile = 3;

  static const _destinations = [
    NavDestination('Home', Icons.home_outlined, Icons.home_rounded),
    NavDestination('Practice', Icons.bolt_outlined, Icons.bolt_rounded),
    NavDestination('Words', Icons.menu_book_outlined, Icons.menu_book_rounded),
    NavDestination(
      'Profile',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  int _tab = _home;

  /// Tabs are built on first visit, then kept alive.
  final _visited = <int>{_home};

  void _select(int tab) {
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = tab;
      _visited.add(tab);
    });
  }

  void _openTopic(Topic topic) {
    Navigator.of(context).push(
      TopicScreen.route(topic, sessionSize: widget.profile.dailyGoal.words),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = (widget.now ?? DateTime.now)();

    Widget tab(int i) => switch (i) {
      _home => HomeTab(
        profile: widget.profile,
        today: today,
        onOpenTopic: _openTopic,
        onOpenProfile: () => _select(_profile),
      ),
      _practice => PracticeTab(
        dailyGoal: widget.profile.dailyGoal.words,
        profile: widget.profile,
      ),
      _words => WordsTab(
        sessionSize: widget.profile.dailyGoal.words,
        profile: widget.profile,
      ),
      _ => ProfileTab(profile: widget.profile),
    };

    return PopScope(
      // Android back from another tab returns Home before leaving the app.
      canPop: _tab == _home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(_home);
      },
      child: Scaffold(
        extendBody: true,
        body: AppBackground(
          child: Stack(
            children: [
              Positioned.fill(child: _body(tab)),
              // Soft fade so content slides under the floating nav gracefully.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.paddingOf(context).bottom + 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.navy950.withValues(alpha: 0),
                          AppColors.navy950.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppNavBar(
          destinations: _destinations,
          index: _tab,
          onChanged: _select,
        ),
      ),
    );
  }

  Widget _body(Widget Function(int) tab) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Stack(
            children: [
              for (final i in _visited)
                _TabLayer(key: ValueKey(i), active: i == _tab, child: tab(i)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Keeps a tab alive while hidden; cross-fades when switching.
class _TabLayer extends StatelessWidget {
  const _TabLayer({super.key, required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(
          excluding: !active,
          child: AnimatedOpacity(
            opacity: active ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              offset: active ? Offset.zero : const Offset(0, 0.015),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
