import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simple conversation prompts shown before/during a meeting — a
/// differentiator, not an AI chatbot. Just a sheet, not a route.
class ConversationStartersSheet extends StatefulWidget {
  const ConversationStartersSheet({super.key});

  @override
  State<ConversationStartersSheet> createState() =>
      _ConversationStartersSheetState();
}

class _ConversationStartersSheetState extends State<ConversationStartersSheet> {
  static const _prompts = [
    "What's something you've been enjoying lately?",
    "What's a place you'd love to visit?",
    'What are you currently learning?',
    "What's the best meal you've had this year?",
    'What do you do to unwind after a long week?',
    "What's a small thing that made you smile recently?",
  ];

  late String _current = _prompts[Random().nextInt(_prompts.length)];

  void _another() {
    HapticFeedback.selectionClick();
    setState(() {
      String next;
      do {
        next = _prompts[Random().nextInt(_prompts.length)];
      } while (next == _current && _prompts.length > 1);
      _current = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'CONVERSATION STARTER',
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _current,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _another,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary.withOpacity(0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Another one',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convenience for opening the sheet from anywhere.
void showConversationStartersSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const ConversationStartersSheet(),
  );
}
