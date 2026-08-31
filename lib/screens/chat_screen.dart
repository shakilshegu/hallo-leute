import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';
import 'package:poppylo/widgets/conversation_starters_sheet.dart';

class ChatScreen extends StatelessWidget {
  final String meetingId;
  const ChatScreen({super.key, required this.meetingId});

  void _openSafetyCenter(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.safetyPath(meetingId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: colorScheme.primary,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Sarah, 27',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.shield_outlined),
                  color: colorScheme.primary,
                  onPressed: () => _openSafetyCenter(context),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: colorScheme.primary),
                  onSelected: (value) {
                    if (value == 'cancel') {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.home);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Cancel Meeting',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Meeting status pill: ☕ date/time · café
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE6EBE6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '☕ Saturday · 5:00 PM · Brew Lab',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Chat list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildIncomingMessage(
                  context: context,
                  text:
                      'Hi! So excited for Saturday. Do you have a favorite spot in mind, or should we just meet near the park?',
                  imageUrl:
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
                ),
                const SizedBox(height: 24),
                _buildOutgoingMessage(
                  context: context,
                  text:
                      "Hey Sarah! I was thinking that new place, 'Origin Roasters' on 5th. It's usually pretty quiet around 5.",
                ),
                const SizedBox(height: 24),
                _buildIncomingMessage(
                  context: context,
                  text:
                      "Oh perfect! I've been wanting to try their pour-over. See you there! ☕️",
                  imageUrl:
                      null, // Don't repeat avatar for consecutive messages if preferred, but mockup has it isolated anyway
                ),
              ],
            ),
          ),
          // Input area
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F8),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Conversation starters',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => showConversationStartersSheet(context),
                        child: Icon(Icons.lightbulb_outline,
                            color: colorScheme.primary.withOpacity(0.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward,
                          color: colorScheme.onPrimary, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingMessage({
    required BuildContext context,
    required String text,
    String? imageUrl,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageUrl != null)
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(imageUrl),
          )
        else
          const SizedBox(width: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFE6EBE6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                height: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 48), // Spacer
      ],
    );
  }

  Widget _buildOutgoingMessage({
    required BuildContext context,
    required String text,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 48), // Spacer
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
