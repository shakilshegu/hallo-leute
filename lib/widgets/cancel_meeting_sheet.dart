import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';

class CancelMeetingSheet extends StatefulWidget {
  const CancelMeetingSheet({super.key});

  @override
  State<CancelMeetingSheet> createState() => _CancelMeetingSheetState();
}

class _CancelMeetingSheetState extends State<CancelMeetingSheet> {
  String _selectedReason = 'Something came up';

  final List<String> _reasons = [
    'Something came up',
    "I don't feel comfortable",
    'Plans changed',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9F8), // Match background exactly
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
          // Drag handle
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
            'Cancel this Coffee Meet?',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll let Sarah know",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          // Radio list
          ..._reasons.map((reason) => _buildRadioOption(
                context: context,
                label: reason,
                isSelected: _selectedReason == reason,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedReason = reason;
                  });
                },
              )),

          const SizedBox(height: 32),

          // Keep meeting button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context); // just close the sheet
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
                'Keep meeting',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cancel text button
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // close the sheet
              context.go(AppRoutes.home);
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Cancel meeting',
              style: textTheme.labelLarge?.copyWith(
                color: const Color(0xFFD32F2F),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B3B2B)
                      : Colors.grey.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B3B2B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
