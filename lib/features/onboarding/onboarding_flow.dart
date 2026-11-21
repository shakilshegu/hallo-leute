import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../data/progress.dart';
import '../../services/reminders.dart';
import '../home/home_content.dart';
import '../home/home_screen.dart';
import 'onboarding_data.dart';
import 'steps/daily_goal_step.dart';
import 'steps/goal_step.dart';
import 'steps/level_step.dart';
import 'steps/name_step.dart';
import 'steps/popups_step.dart';
import 'steps/ready_step.dart';

/// Name → goals → level → daily goal → "Alles klar!".
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});

  /// Called with the answers when the learner taps "Start learning".
  final ValueChanged<OnboardingData>? onFinished;

  static Route<void> route({ValueChanged<OnboardingData>? onFinished}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => OnboardingFlow(onFinished: onFinished),
      transitionsBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _questionCount = 5;
  static const _popupsIndex = 4;
  static const _readyIndex = 5;

  final _pages = PageController();
  final _nameController = TextEditingController();
  final _data = OnboardingData();
  int _step = 0;

  bool get _isReady => _step == _readyIndex;

  bool get _canContinue => switch (_step) {
    0 => _data.name.trim().isNotEmpty,
    1 => _data.goals.isNotEmpty,
    2 => _data.level != null,
    _ => true,
  };

  @override
  void dispose() {
    _pages.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _pages.jumpToPage(step);
    } else {
      _pages.animateToPage(
        step,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _next() {
    if (!_canContinue) return;
    if (_isReady) {
      _finish();
      return;
    }
    if (_step == _popupsIndex) _applyPopups();
    _goTo(_step + 1);
  }

  /// Asks for notification permission (only if pop-ups are on) and
  /// schedules the chosen number of word pop-ups.
  Future<void> _applyPopups() async {
    final reminders = RemindersScope.maybeOf(context);
    if (reminders == null) return;
    final progress = ProgressScope.of(context);
    var perDay = _data.wordPopups;
    if (perDay > 0 && !await reminders.requestPermission()) perDay = 0;
    await reminders.setPopups(
      perDay,
      wordsFor: wordsForDay,
      isLearned: progress.isLearned,
    );
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).maybePop();
    } else {
      _goTo(_step - 1);
    }
  }

  void _finish() {
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished(_data);
      return;
    }
    // Remember the learner so the next launch opens straight on Home.
    ProgressScope.of(context).saveProfile(_data);
    Navigator.of(context)
        .pushAndRemoveUntil(HomeScreen.route(_data), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      NameStep(
        controller: _nameController,
        onChanged: (v) => setState(() => _data.name = v),
        onSubmitted: _next,
      ),
      GoalStep(
        selected: _data.goals,
        onToggle: (g) => setState(() {
          if (!_data.goals.remove(g)) _data.goals.add(g);
        }),
      ),
      LevelStep(
        selected: _data.level,
        onSelect: (l) => setState(() => _data.level = l),
      ),
      DailyGoalStep(
        selected: _data.dailyGoal,
        onSelect: (d) => setState(() => _data.dailyGoal = d),
      ),
      PopupsStep(
        selected: _data.wordPopups,
        onSelect: (n) => setState(() => _data.wordPopups = n),
      ),
      ReadyStep(data: _data),
    ];

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    _TopBar(
                      step: _step,
                      total: _questionCount,
                      hidden: _isReady,
                      onBack: _back,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pages,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final step in steps)
                            SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                16,
                              ),
                              child: step,
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                      child: PrimaryButton(
                        label: _isReady ? 'Start learning' : 'Continue',
                        onPressed: _canContinue ? _next : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.step,
    required this.total,
    required this.hidden,
    required this.onBack,
  });

  final int step;
  final int total;
  final bool hidden;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final current = math.min(step + 1, total);
    return AnimatedOpacity(
      opacity: hidden ? 0 : 1,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: hidden,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Back',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.cream.withValues(alpha: 0.07),
                  foregroundColor: AppColors.cream,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: _ProgressBar(value: current / total)),
              const SizedBox(width: 14),
              Text(
                '$current/$total',
                style: AppText.body(
                  13,
                  weight: FontWeight.w800,
                  color: AppColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress',
      value: '${(value * 100).round()}%',
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.cream.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.mustard,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
