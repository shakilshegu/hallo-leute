import 'package:flutter/material.dart';

import '../../../shared/widgets/reveal.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';
import '../widgets/onboarding_widgets.dart';

class NameStep extends StatelessWidget {
  const NameStep({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final name = controller.text.trim();
    final shown = name.isEmpty ? '…' : name;

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.navyLine.withValues(alpha: 0.6)),
    );

    return StaggeredColumn(
      children: [
        const StepHeader(
          eyebrow: 'Hallo!',
          title: 'What should we call you?',
          subtitle: "We'll use your name to cheer you on.",
        ),
        const SizedBox(height: 28),
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 24,
          cursorColor: AppColors.mustard,
          style: AppText.display(22, color: AppColors.cream),
          decoration: InputDecoration(
            hintText: 'Your first name',
            hintStyle: AppText.display(
              22,
              weight: FontWeight.w500,
              color: AppColors.cream.withValues(alpha: 0.3),
            ),
            counterText: '',
            filled: true,
            fillColor: AppColors.navy800.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.mustard,
                width: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TipCard(
          label: 'SAY IT IN GERMAN',
          german: 'Ich heiße $shown.',
          english: 'My name is $shown.',
        ),
      ],
    );
  }
}
