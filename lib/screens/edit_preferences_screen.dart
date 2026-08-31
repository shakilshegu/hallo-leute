import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/profile_api.dart';
import 'package:poppylo/state/profile_controller.dart';

class EditPreferencesScreen extends ConsumerStatefulWidget {
  const EditPreferencesScreen({super.key});

  @override
  ConsumerState<EditPreferencesScreen> createState() =>
      _EditPreferencesScreenState();
}

class _EditPreferencesScreenState extends ConsumerState<EditPreferencesScreen> {
  static const _green = Color(0xFF1B3B2B);
  static const _distances = [2, 5, 10];
  static const _styleLabels = [
    'Casual',
    'Deep',
    'Career',
    'Hobbies',
    'Anything'
  ];

  RangeValues _ageRange = const RangeValues(18, 100);
  int _distance = 5;
  final Set<String> _styles = {};

  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  void _prefill(UserMe me) {
    if (_prefilled) return;
    _prefilled = true;
    final p = me.preferences;
    if (p != null) {
      _ageRange = RangeValues(
        p.minAge.clamp(18, 80).toDouble(),
        p.maxAge.clamp(18, 80).toDouble(),
      );
      _distance = _distances.reduce((a, b) =>
          (a - p.maxDistanceKm).abs() <= (b - p.maxDistanceKm).abs() ? a : b);
      _styles
        ..clear()
        ..addAll(p.conversationStyles.map(conversationStyleLabelFromApi));
    }
    if (_styles.isEmpty) _styles.add('Deep');
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_styles.isEmpty) {
      _snack('Pick at least one conversation style.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      await ref.read(profileApiProvider).setPreferences(
            minAge: _ageRange.start.round(),
            maxAge: _ageRange.end.round(),
            maxDistanceKm: _distance,
            conversationStyles:
                _styles.map((l) => kConversationStyleLabelToApi[l]!).toList(),
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _saving = false;
        _error = e.message;
      });
      return;
    }

    ref.invalidate(meProvider);
    if (mounted) context.pop();
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final me = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: me.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _green)),
          error: (_, __) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Couldn't load your preferences"),
                TextButton(
                  onPressed: () => ref.invalidate(meProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (data) {
            _prefill(data);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
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
                        'Preferences',
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AGE RANGE',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary.withOpacity(0.5),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_ageRange.start.round()}–${_ageRange.end.round()}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            RangeSlider(
                              values: _ageRange,
                              min: 18,
                              max: 80,
                              activeColor: colorScheme.primary,
                              onChanged: _saving
                                  ? null
                                  : (v) => setState(() => _ageRange = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel('DISTANCE', textTheme, colorScheme),
                      const SizedBox(height: 16),
                      Row(
                        children: _distances.map((km) {
                          final sel = _distance == km;
                          return Expanded(
                            child: Padding(
                              padding:
                                  EdgeInsets.only(right: km != 10 ? 12.0 : 0),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _distance = km);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? colorScheme.primary
                                        : colorScheme.primary.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: sel
                                          ? colorScheme.primary
                                          : colorScheme.primary
                                              .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Text(
                                    '$km km',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: sel
                                          ? colorScheme.onPrimary
                                          : colorScheme.primary,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel(
                          'CONVERSATION STYLE', textTheme, colorScheme),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12.0,
                        runSpacing: 12.0,
                        children: _styleLabels.map((style) {
                          final sel = _styles.contains(style);
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                if (sel) {
                                  _styles.remove(style);
                                } else {
                                  _styles.add(style);
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? colorScheme.primary
                                    : colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                style,
                                style: textTheme.labelSmall?.copyWith(
                                  color: sel
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                    child: Text(_error!,
                        style: textTheme.bodySmall
                            ?.copyWith(color: Colors.red.shade400)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _green.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Save changes',
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String t, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      t,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.primary.withOpacity(0.5),
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
