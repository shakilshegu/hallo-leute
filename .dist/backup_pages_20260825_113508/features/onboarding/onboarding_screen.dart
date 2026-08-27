import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poppylo/features/onboarding/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            if (_currentPage > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: LinearProgressIndicator(
                  value: _currentPage / 5,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button use
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomeStep(),
                  _buildGoalStep(),
                  _buildLevelStep(),
                  _buildTimeStep(),
                  _buildMotivationStep(),
                  _buildNotificationStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(
            Icons.language,
            size: 100,
            color: Color(0xFFFF5252),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to Poppylo',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Learn German the fun and easy way.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Get Started'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              'I already have an account',
              style: TextStyle(fontSize: 16, color: Color(0xFFFF5252)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    final options = ['Travel', 'Career', 'Brain Training', 'Just for fun', 'School/University'];
    return _SelectionStep(
      title: 'Why are you learning German?',
      options: options,
      selectedValue: ref.watch(onboardingProvider).learningGoal,
      onSelected: (value) {
        ref.read(onboardingProvider.notifier).setLearningGoal(value);
      },
      onNext: _nextPage,
    );
  }

  Widget _buildLevelStep() {
    final options = [
      'Absolute Beginner',
      'I know a few words',
      'I can hold basic conversations',
      'Intermediate or above'
    ];
    return _SelectionStep(
      title: 'How much German do you know?',
      options: options,
      selectedValue: ref.watch(onboardingProvider).currentLevel,
      onSelected: (value) {
        ref.read(onboardingProvider.notifier).setCurrentLevel(value);
      },
      onNext: _nextPage,
    );
  }

  Widget _buildTimeStep() {
    final options = ['5 mins / day', '10 mins / day', '15 mins / day', '30 mins / day'];
    final selectedGoal = ref.watch(onboardingProvider).dailyGoalMinutes;
    final selectedString = selectedGoal != null ? '$selectedGoal mins / day' : null;

    return _SelectionStep(
      title: 'What is your daily goal?',
      options: options,
      selectedValue: selectedString,
      onSelected: (value) {
        final mins = int.tryParse(value.split(' ').first) ?? 10;
        ref.read(onboardingProvider.notifier).setDailyGoal(mins);
      },
      onNext: _nextPage,
    );
  }

  Widget _buildMotivationStep() {
    final options = ['Casual Learner', 'Regular Learner', 'Serious Learner', 'Intense Learner'];
    return _SelectionStep(
      title: 'How motivated are you?',
      options: options,
      selectedValue: ref.watch(onboardingProvider).motivation,
      onSelected: (value) {
        ref.read(onboardingProvider.notifier).setMotivation(value);
      },
      onNext: _nextPage,
    );
  }

  Widget _buildNotificationStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(
            Icons.notifications_active,
            size: 100,
            color: Color(0xFFFFC107),
          ),
          const SizedBox(height: 32),
          const Text(
            'Keep your streak alive!',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Turn on notifications to get daily reminders. Practice every day to build a habit.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              ref.read(onboardingProvider.notifier).setNotifications(true);
              _nextPage();
            },
            child: const Text('Allow Notifications'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ref.read(onboardingProvider.notifier).setNotifications(false);
              _nextPage();
            },
            child: const Text(
              'Not now',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionStep extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;
  final VoidCallback onNext;

  const _SelectionStep({
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selectedValue;
                return InkWell(
                  onTap: () => onSelected(option),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: selectedValue != null ? onNext : null,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
