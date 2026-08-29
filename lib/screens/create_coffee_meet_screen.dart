import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/match_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/search_controller.dart';

class CreateCoffeeMeetScreen extends ConsumerStatefulWidget {
  const CreateCoffeeMeetScreen({super.key});

  @override
  ConsumerState<CreateCoffeeMeetScreen> createState() =>
      _CreateCoffeeMeetScreenState();
}

class _CreateCoffeeMeetScreenState
    extends ConsumerState<CreateCoffeeMeetScreen> {
  String _selectedDate = 'Today';
  String _selectedTime = '3:00 PM';
  String _selectedDuration = '45 min';
  double _radiusKm = 10;
  final Set<String> _selectedWhy = {'Make friends'};
  final Set<String> _selectedConversation = {'Deep'};

  final List<String> _dateOptions = ['Today', 'Tomorrow', 'Pick Date'];
  final List<String> _timeOptions = [
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
    '7:00 PM'
  ];
  final List<String> _durationOptions = ['30 min', '45 min', '60 min'];
  final List<double> _distanceOptions = [2, 5, 10];
  final List<String> _whyOptions = [
    'Make friends',
    'Networking',
    'Shared interests',
    'Dating',
    'Conversation'
  ];
  final List<String> _conversationOptions = [
    'Casual',
    'Deep',
    'Career',
    'Hobbies',
    'Anything'
  ];

  DateTime _timeForSelection() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 15);
  }

  void _startSearching() {
    HapticFeedback.mediumImpact();
    ref.read(searchControllerProvider.notifier).start(
          MeetRequest(
            dateLabel: _selectedDate,
            timeLabel: _selectedTime,
            time: _timeForSelection(),
            durationLabel: _selectedDuration,
            radiusKm: _radiusKm,
            whyLabels: _selectedWhy.toList(),
            conversationLabels: _selectedConversation.toList(),
          ),
        );
    context.go(AppRoutes.searching);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black54,
          letterSpacing: 1.5,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSingleSelectChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
    bool scrollable = false,
  }) {
    final children = options.map((label) {
      final isSelected = label == selectedValue;
      final isPickDate = label == 'Pick Date';
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected(label);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1D3D33) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPickDate) ...[
                Icon(
                  Icons.calendar_month,
                  size: 16,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Wrap(
          spacing: 12,
          children: children,
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children,
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<String> onSelected,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((label) {
        final isSelected = selectedValues.contains(label);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onSelected(label);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1D3D33) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  _buildSectionTitle('WHEN'),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: _dateOptions.map((label) {
                        final isSelected = label == _selectedDate;
                        final isPickDate = label == 'Pick Date';
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedDate = label);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1D3D33)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isPickDate) ...[
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  _buildSectionTitle('TIME'),
                  _buildSingleSelectChips(
                    options: _timeOptions,
                    selectedValue: _selectedTime,
                    onSelected: (val) => setState(() => _selectedTime = val),
                    scrollable: true,
                  ),
                  _buildSectionTitle('HOW LONG'),
                  _buildSingleSelectChips(
                    options: _durationOptions,
                    selectedValue: _selectedDuration,
                    onSelected: (val) => setState(() => _selectedDuration = val),
                  ),
                  _buildSectionTitle('HOW FAR'),
                  Row(
                    children: _distanceOptions.map((dist) {
                      final label = '${dist.toInt()} km';
                      final isSelected = _radiusKm == dist;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _radiusKm = dist);
                          },
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1D3D33)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  _buildSectionTitle('WHY'),
                  _buildMultiSelectChips(
                    options: _whyOptions,
                    selectedValues: _selectedWhy,
                    onSelected: (val) {
                      setState(() {
                        if (_selectedWhy.contains(val)) {
                          _selectedWhy.remove(val);
                        } else {
                          _selectedWhy.add(val);
                        }
                      });
                    },
                  ),
                  _buildSectionTitle('CONVERSATION'),
                  _buildMultiSelectChips(
                    options: _conversationOptions,
                    selectedValues: _selectedConversation,
                    onSelected: (val) {
                      setState(() {
                        if (_selectedConversation.contains(val)) {
                          _selectedConversation.remove(val);
                        } else {
                          _selectedConversation.add(val);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startSearching,
                  icon: const Icon(Icons.search, color: Colors.white),
                  label: const Text(
                    'Find my match',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F261E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
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

