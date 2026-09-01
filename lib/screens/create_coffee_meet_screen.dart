import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/models/match_models.dart';
import 'package:poppylo/models/profile_models.dart'
    show kConversationStyleLabelToApi;
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';
import 'package:poppylo/state/coffee_request_controller.dart';
import 'package:poppylo/state/search_controller.dart';

const _kInk = Color(0xFF1D3D33);
const _kBg = Color(0xFFF3F1EB);
const _kButton = Color(0xFF0F261E);

class CreateCoffeeMeetScreen extends ConsumerStatefulWidget {
  const CreateCoffeeMeetScreen({super.key});

  @override
  ConsumerState<CreateCoffeeMeetScreen> createState() =>
      _CreateCoffeeMeetScreenState();
}

class _CreateCoffeeMeetScreenState
    extends ConsumerState<CreateCoffeeMeetScreen> {
  String _selectedDate = 'Today';
  DateTime? _pickedDate;
  String _selectedTime = '3:00 PM';
  String _selectedDuration = '45 min';
  double _radiusKm = 10;
  final Set<String> _selectedWhy = {'Make friends'};
  final Set<String> _selectedConversation = {'Deep'};

  bool _submitting = false;
  String? _error;

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

  /// Create Coffee Meet "WHY" labels → backend `Purpose` enum values.
  static const Map<String, String> _purposeApi = {
    'Make friends': 'friends',
    'Networking': 'networking',
    'Shared interests': 'shared_interests',
    'Dating': 'dating',
    'Conversation': 'good_conversation',
  };

  // --- request payload mapping --------------------------------------------

  String get _apiDate {
    final now = DateTime.now();
    final d = switch (_selectedDate) {
      'Tomorrow' => now.add(const Duration(days: 1)),
      'Pick Date' => _pickedDate ?? now,
      _ => now,
    };
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  /// "3:00 PM" → "15:00"
  String get _apiStartTime {
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(_selectedTime);
    var hour = int.tryParse(match?.group(1) ?? '') ?? 12;
    final minute = match?.group(2) ?? '00';
    final isPm = _selectedTime.toUpperCase().contains('PM');
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return '${hour.toString().padLeft(2, '0')}:$minute';
  }

  /// "45 min" → 45
  int get _apiDuration =>
      int.tryParse(_selectedDuration.replaceAll(RegExp(r'\D'), '')) ?? 45;

  DateTime _timeForSelection() {
    final now = DateTime.now();
    final hour = int.parse(_apiStartTime.split(':').first);
    return DateTime(now.year, now.month, now.day, hour);
  }

  String? _validate() {
    if (_selectedDate == 'Pick Date' && _pickedDate == null) {
      return 'Pick a date to continue.';
    }
    if (_selectedWhy.isEmpty) return 'Choose why you want to meet.';
    if (_selectedConversation.isEmpty) {
      return 'Choose a conversation style.';
    }
    return null;
  }

  // --- actions -----------------------------------------------------------

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedDate ?? now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (!mounted) return;
    setState(() {
      _selectedDate = 'Pick Date';
      if (picked != null) _pickedDate = picked;
    });
  }

  Future<void> _startSearching() async {
    if (_submitting) return;

    final validationError = _validate();
    if (validationError != null) {
      HapticFeedback.heavyImpact();
      setState(() => _error = validationError);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();

    try {
      final request = await ref.read(coffeeRequestApiProvider).create(
            date: _apiDate,
            startTime: _apiStartTime,
            durationMinutes: _apiDuration,
            maxDistanceKm: _radiusKm.toInt(),
            purpose: _purposeApi[_selectedWhy.first] ?? 'good_conversation',
            conversationStyle:
                kConversationStyleLabelToApi[_selectedConversation.first] ??
                    'anything',
          );

      // Keep the local MeetRequest so the Searching screen header still reads.
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
      ref.invalidate(activeCoffeeRequestProvider);

      if (!mounted) return;
      context.go(AppRoutes.searching, extra: request.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _submitting = false;
        _error = coffeeRequestErrorMessage(e.statusCode, e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _cancelActive(String id) async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(coffeeRequestApiProvider).cancel(id);
      ref.invalidate(activeCoffeeRequestProvider);
      if (mounted) setState(() => _submitting = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = coffeeRequestErrorMessage(e.statusCode, e.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  // --- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activeCoffeeRequestProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: active.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _kInk),
          ),
          // A failed active-check must not block the user from trying.
          error: (_, __) => _buildForm(),
          data: (req) => (req != null && req.isPending)
              ? _buildAlreadySearching(req)
              : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildAlreadySearching(CoffeeRequest req) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kInk.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, color: _kInk, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            "You're already searching for a coffee match.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kInk,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${req.startTime} · ${req.maxDistanceKm} km · '
            '${req.durationMinutes} min',
            textAlign: TextAlign.center,
            style: TextStyle(color: _kInk.withOpacity(0.6)),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.go(AppRoutes.searching, extra: req.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kButton,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Continue searching',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _submitting ? null : () => _cancelActive(req.id),
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _kInk,
                    ),
                  )
                : Text(
                    'Cancel this request',
                    style: TextStyle(
                      color: _kInk.withOpacity(0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  /// The form fills the screen: the six sections share the vertical space
  /// evenly and the action button is pinned to the bottom. On very short
  /// screens where the content genuinely cannot fit, it becomes scrollable
  /// rather than overflowing.
  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(child: _formBody()),
          ),
        );
      },
    );
  }

  Widget _formBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _section('WHEN', _whenControl()),
                _section(
                    'TIME',
                    _wrapChips(
                      options: _timeOptions,
                      isSelected: (v) => v == _selectedTime,
                      onTap: (v) => setState(() => _selectedTime = v),
                    )),
                _section(
                    'HOW LONG',
                    _wrapChips(
                      options: _durationOptions,
                      isSelected: (v) => v == _selectedDuration,
                      onTap: (v) => setState(() => _selectedDuration = v),
                    )),
                _section(
                    'HOW FAR',
                    _wrapChips(
                      options: [
                        for (final d in _distanceOptions) '${d.toInt()} km'
                      ],
                      isSelected: (v) => v == '${_radiusKm.toInt()} km',
                      onTap: (v) => setState(
                        () => _radiusKm =
                            double.parse(v.replaceAll(RegExp(r'\D'), '')),
                      ),
                    )),
                _section(
                    'WHY',
                    _wrapChips(
                      options: _whyOptions,
                      isSelected: _selectedWhy.contains,
                      onTap: (v) => setState(() {
                        _selectedWhy.contains(v)
                            ? _selectedWhy.remove(v)
                            : _selectedWhy.add(v);
                      }),
                    )),
                _section(
                    'CONVERSATION',
                    _wrapChips(
                      options: _conversationOptions,
                      isSelected: _selectedConversation.contains,
                      onTap: (v) => setState(() {
                        _selectedConversation.contains(v)
                            ? _selectedConversation.remove(v)
                            : _selectedConversation.add(v);
                      }),
                    )),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: Colors.red.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _error!,
                      style:
                          TextStyle(color: Colors.red.shade400, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _startSearching,
              icon: _submitting
                  ? const SizedBox.shrink()
                  : const Icon(Icons.search, color: Colors.white),
              label: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Find my match',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kButton,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _kButton,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            letterSpacing: 1.5,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _whenControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: _dateOptions.map((label) {
          final isSelected = label == _selectedDate;
          final isPickDate = label == 'Pick Date';
          final text = isPickDate && _pickedDate != null
              ? '${_pickedDate!.day}/${_pickedDate!.month}'
              : (isPickDate ? 'Pick date' : label);
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                if (isPickDate) {
                  _pickDate();
                } else {
                  setState(() => _selectedDate = label);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? _kInk : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black54,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _wrapChips({
    required List<String> options,
    required bool Function(String) isSelected,
    required ValueChanged<String> onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((label) {
        final selected = isSelected(label);
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(label);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? _kInk : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: selected ? Colors.white : Colors.black87,
                fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
