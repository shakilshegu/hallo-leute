import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/purpose_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  RangeValues _ageRange = const RangeValues(24, 34);
  int _selectedDistance = 5; // km
  
  final List<String> _conversationStyles = ['Casual', 'Deep', 'Career', 'Hobbies', 'Anything'];
  final Set<String> _selectedStyles = {'Deep', 'Anything'};
  
  bool _isLoading = false;

  void _toggleStyle(String style) {
    if (_isLoading) return;
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedStyles.contains(style)) {
        _selectedStyles.remove(style);
      } else {
        _selectedStyles.add(style);
      }
    });
  }

  void _handleSave() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PurposeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
          ),
        ),
        title: Text(
          'Preferences',
          style: textTheme.headlineSmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Who would you enjoy meeting?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Adjust your preferences to find the perfect coffee companion.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Age Range
                    Semantics(
                      label: 'Age Range from ${_ageRange.start.round()} to ${_ageRange.end.round()}',
                      slider: true,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
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
                                  '${_ageRange.start.round()}-${_ageRange.end.round()}',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor: colorScheme.primary.withOpacity(0.1),
                                thumbColor: colorScheme.primary,
                                overlayColor: colorScheme.primary.withOpacity(0.1),
                                trackHeight: 6,
                              ),
                              child: RangeSlider(
                                values: _ageRange,
                                min: 18,
                                max: 65,
                                onChanged: _isLoading ? null : (values) {
                                  setState(() {
                                    _ageRange = values;
                                  });
                                },
                                onChangeEnd: (_) {
                                  HapticFeedback.lightImpact();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Distance
                    Text(
                      'DISTANCE',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [2, 5, 10].map((km) {
                        final isSelected = _selectedDistance == km;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: km != 10 ? 12.0 : 0,
                            ),
                            child: Semantics(
                              button: true,
                              selected: isSelected,
                              label: '$km kilometers',
                              child: GestureDetector(
                                onTap: _isLoading ? null : () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _selectedDistance = km;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.04),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.1),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$km km',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // Conversation Style
                    Text(
                      'CONVERSATION STYLE',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 16.0,
                      children: _conversationStyles.map((style) {
                        final isSelected = _selectedStyles.contains(style);
                        return Semantics(
                          button: true,
                          selected: isSelected,
                          label: style,
                          child: GestureDetector(
                            onTap: () => _toggleStyle(style),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                style,
                                style: textTheme.labelSmall?.copyWith(
                                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
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
            ),
            
            // Save Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedOpacity(
                opacity: _isLoading ? 0.7 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            'Save preferences',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
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
}
