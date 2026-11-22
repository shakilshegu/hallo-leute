import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../onboarding/onboarding_data.dart';

/// Change name, level, daily goal and reasons after onboarding.
Future<void> showEditProfile(BuildContext context, OnboardingData profile) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navy,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _EditProfileSheet(profile: profile),
  );
}

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.profile});

  final OnboardingData profile;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final _name = TextEditingController(text: widget.profile.name);
  late GermanLevel? _level = widget.profile.level;
  late DailyGoal _goal = widget.profile.dailyGoal;
  late final Set<LearningGoal> _reasons = {...widget.profile.goals};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final p = widget.profile;
    // A new setup level also moves the study level (picker can override).
    if (_level != p.level) p.studyLevel = null;
    p
      ..name = _name.text.trim()
      ..level = _level
      ..dailyGoal = _goal;
    p.goals
      ..clear()
      ..addAll(_reasons);
    await ProgressScope.of(context).saveProfile(p);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: AppText.body(
        12,
        weight: FontWeight.w800,
        color: AppColors.creamMuted,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.mustard
              : AppColors.cream.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: AppText.body(
            13.5,
            weight: FontWeight.w800,
            color: selected ? AppColors.navy : AppColors.cream,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.navyLine.withValues(alpha: 0.6)),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.cream.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit profile',
                  style: AppText.display(24, color: AppColors.cream),
                ),
                _label('Name'),
                TextField(
                  controller: _name,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: AppColors.mustard,
                  style: AppText.body(
                    16.5,
                    weight: FontWeight.w700,
                    color: AppColors.cream,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.navy800.withValues(alpha: 0.6),
                    enabledBorder: border,
                    focusedBorder: border.copyWith(
                      borderSide: const BorderSide(
                        color: AppColors.mustard,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                _label('Your level'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in GermanLevel.values)
                      _chip(
                        '${l.code} · ${l.title}',
                        _level == l,
                        () => setState(() => _level = l),
                      ),
                  ],
                ),
                _label('Daily goal'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in DailyGoal.values)
                      _chip(
                        '${g.words} words · ${g.title}',
                        _goal == g,
                        () => setState(() => _goal = g),
                      ),
                  ],
                ),
                _label('Learning German for'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in LearningGoal.values)
                      _chip(
                        r.label,
                        _reasons.contains(r),
                        () => setState(() {
                          if (!_reasons.remove(r)) _reasons.add(r);
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _name,
                  builder: (context, v, _) => PrimaryButton(
                    label: 'Save',
                    onPressed: v.text.trim().isEmpty ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
