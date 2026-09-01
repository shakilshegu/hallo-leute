import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/state/safety_controller.dart';

/// Bottom sheet to cancel a confirmed Coffee Meet. Pops with `true` once the
/// backend confirms the cancellation — the caller navigates + refreshes.
class CancelMeetingSheet extends ConsumerStatefulWidget {
  const CancelMeetingSheet({
    super.key,
    required this.meetingId,
    this.partnerName = 'your match',
  });

  final String meetingId;
  final String partnerName;

  @override
  ConsumerState<CancelMeetingSheet> createState() => _CancelMeetingSheetState();
}

class _CancelMeetingSheetState extends ConsumerState<CancelMeetingSheet> {
  String _selectedReason = 'Something came up';
  bool _cancelling = false;

  final List<String> _reasons = const [
    'Something came up',
    "I don't feel comfortable",
    'Plans changed',
    'Other',
  ];

  Future<void> _confirmCancel() async {
    if (_cancelling) return;
    setState(() => _cancelling = true);
    try {
      await ref.read(safetyApiProvider).cancelMeeting(
            widget.meetingId,
            reason: kCancelReasonToApi[_selectedReason] ?? 'other',
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(safetyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            'Cancel this Coffee Meet?',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "We'll let ${widget.partnerName} know",
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ..._reasons.map((reason) => _buildRadioOption(
                context: context,
                label: reason,
                isSelected: _selectedReason == reason,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedReason = reason);
                },
              )),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed:
                  _cancelling ? null : () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3B2B),
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
          TextButton(
            onPressed: _cancelling ? null : _confirmCancel,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD32F2F),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _cancelling
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFD32F2F)),
                  )
                : Text(
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
