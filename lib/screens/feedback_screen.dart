import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/feedback_sent_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _rating = 0;
  String? _conversationFeel;
  String? _meetAgain;
  final Set<String> _stoodOut = {};

  final List<String> _feelOptions = ['GREAT', 'GOOD', 'OKAY', 'NOT GREAT'];
  final List<String> _meetOptions = ['YES', 'MAYBE', 'NO'];
  final List<String> _stoodOutOptions = [
    'FRIENDLY',
    'INTERESTING',
    'EASY TO TALK TO',
    'GREAT CONVERSATION',
    'NOT A GOOD FIT'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Warm beige background from mockup
      body: SafeArea(
        child: Column(
          children: [
            // Header with Close button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: colorScheme.primary,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'FEEDBACK',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for centering
                ],
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  const SizedBox(height: 16),
                  // Profile Image
                  Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // How was your coffee?
                  Text(
                    'How was your coffee?',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Star Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: const Color(0xFFE6A316), // Gold color
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 48),
                  
                  // Question 1
                  _buildQuestionLabel('01', 'How did the conversation feel?', textTheme, colorScheme),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _feelOptions.map((option) => _buildSingleSelectPill(
                      label: option,
                      isSelected: _conversationFeel == option,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _conversationFeel = option);
                      },
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Question 2
                  _buildQuestionLabel('02', 'Would you meet Sarah again?', textTheme, colorScheme),
                  const SizedBox(height: 16),
                  Row(
                    children: _meetOptions.map((option) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildSingleSelectPill(
                          label: option,
                          isSelected: _meetAgain == option,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _meetAgain = option);
                          },
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Question 3
                  _buildQuestionLabel('03', 'What stood out?', textTheme, colorScheme, isOptional: true),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _stoodOutOptions.map((option) => _buildMultiSelectPill(
                      label: option,
                      isSelected: _stoodOut.contains(option),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (_stoodOut.contains(option)) {
                            _stoodOut.remove(option);
                          } else {
                            _stoodOut.add(option);
                          }
                        });
                      },
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    )).toList(),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
            
            // Submit Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const FeedbackSentScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B), // Dark green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'SUBMIT FEEDBACK',
                    style: textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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

  Widget _buildQuestionLabel(String number, String question, TextTheme textTheme, ColorScheme colorScheme, {bool isOptional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.3),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: colorScheme.primary.withOpacity(0.1)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isOptional)
              Text(
                '(Optional)',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleSelectPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B3B2B) : const Color(0xFFE6EBE6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected ? Colors.white : colorScheme.primary.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF1B3B2B) : colorScheme.primary.withOpacity(0.1),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected ? const Color(0xFF1B3B2B) : colorScheme.primary.withOpacity(0.7),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
