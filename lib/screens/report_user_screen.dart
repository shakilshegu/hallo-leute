import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/state/safety_controller.dart';

class ReportUserScreen extends ConsumerStatefulWidget {
  final String userId;
  const ReportUserScreen({super.key, required this.userId});

  @override
  ConsumerState<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends ConsumerState<ReportUserScreen> {
  String? _selectedReason;
  bool _submitting = false;
  bool _submitted = false;
  final TextEditingController _detailsController = TextEditingController();

  final List<String> _reasons = const [
    'Made me uncomfortable',
    'Harassment',
    'Fake profile',
    "Didn't show up",
    'Inappropriate behaviour',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null || _submitting) return;
    setState(() => _submitting = true);
    try {
      await ref.read(safetyApiProvider).reportUser(
            widget.userId,
            reason: kReportReasonToApi[reason] ?? 'other',
            details: _detailsController.text,
          );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(safetyErrorMessage(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: _submitted
            ? _successView(context, textTheme, colorScheme)
            : _form(context, textTheme, colorScheme),
      ),
    );
  }

  Widget _successView(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EBE6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF1B3B2B), size: 34),
          ),
          const SizedBox(height: 24),
          Text(
            'Report submitted',
            style: textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF1B3B2B),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for letting us know. We review every report — the other '
            'person is never told you reported them.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B3B2B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(
    BuildContext context,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final canSubmit = _selectedReason != null && !_submitting;
    return Column(
      children: [
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
                  context.pop();
                },
              ),
              Text(
                'Report',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            children: [
              const SizedBox(height: 16),
              Text(
                'REPORT / USER',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'What happened?',
                style: textTheme.headlineMedium?.copyWith(
                  color: const Color(0xFF1B3B2B),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: _reasons
                      .map((reason) =>
                          _buildReasonItem(reason, colorScheme, textTheme))
                      .toList(),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'OPTIONAL DETAILS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailsController,
                maxLines: 4,
                maxLength: 1000,
                style:
                    textTheme.bodyMedium?.copyWith(color: colorScheme.primary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE6EBE6),
                  hintText: 'Please provide any additional context...',
                  hintStyle: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.primary.withOpacity(0.4)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16, color: colorScheme.primary.withOpacity(0.5)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "We review every report. They won't be told you "
                      'reported them.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA5392B),
                disabledBackgroundColor:
                    const Color(0xFFA5392B).withOpacity(0.4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flag_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Submit report',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonItem(
      String reason, ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = _selectedReason == reason;
    final isLast = reason == _reasons.last;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedReason = reason);
      },
      child: Container(
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                reason,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1B3B2B)
                      : Colors.grey.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1B3B2B),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
