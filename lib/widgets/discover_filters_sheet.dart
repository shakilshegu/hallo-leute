import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/models/profile_models.dart'
    show kInterestCatalog, kPurposeLabelToApi, purposeLabelFromApi;

const _green = Color(0xFF1B3B2B);
const _bg = Color(0xFFF8F9F8);

/// The Discover filter bottom sheet. Pops with a [DiscoverFilters] on Apply,
/// or `DiscoverFilters.none` on Clear. Returns null if dismissed.
class DiscoverFiltersSheet extends StatefulWidget {
  const DiscoverFiltersSheet({super.key, required this.initial});

  final DiscoverFilters initial;

  static Future<DiscoverFilters?> show(
    BuildContext context,
    DiscoverFilters initial,
  ) {
    return showModalBottomSheet<DiscoverFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscoverFiltersSheet(initial: initial),
    );
  }

  @override
  State<DiscoverFiltersSheet> createState() => _DiscoverFiltersSheetState();
}

class _DiscoverFiltersSheetState extends State<DiscoverFiltersSheet> {
  late int? _distance = widget.initial.distanceKm;
  late String? _purpose = widget.initial.purpose;
  late String? _interest = widget.initial.interest;
  late String? _availability = widget.initial.availability;

  static const _distances = [5, 10, 25];
  static const _availabilities = {
    'THIS_WEEK': 'This week',
    'THIS_WEEKEND': 'This weekend',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Filters',
            style: textTheme.titleLarge?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Distance'),
                  _chips(
                    options: {
                      for (final d in _distances) '$d': '$d km',
                    },
                    selected: _distance == null ? null : '$_distance',
                    onSelect: (v) => setState(
                      () => _distance = v == null ? null : int.parse(v),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('Purpose'),
                  _chips(
                    options: {
                      for (final e in kPurposeLabelToApi.entries)
                        e.value: e.key,
                    },
                    selected: _purpose,
                    onSelect: (v) => setState(() => _purpose = v),
                  ),
                  const SizedBox(height: 20),
                  _label('Interest'),
                  _chips(
                    options: {
                      for (final label in kInterestCatalog)
                        label.toLowerCase(): label,
                    },
                    selected: _interest,
                    onSelect: (v) => setState(() => _interest = v),
                  ),
                  const SizedBox(height: 20),
                  _label('Availability'),
                  _chips(
                    options: _availabilities,
                    selected: _availability,
                    onSelect: (v) => setState(() => _availability = v),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context, DiscoverFilters.none);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: BorderSide(color: _green.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(
                      context,
                      DiscoverFilters(
                        distanceKm: _distance,
                        purpose: _purpose,
                        interest: _interest,
                        availability: _availability,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _green.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
        ),
      );

  /// A wrap of single-select chips. Tapping the selected one clears it.
  Widget _chips({
    required Map<String, String> options, // value -> label
    required String? selected,
    required ValueChanged<String?> onSelect,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in options.entries)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(selected == entry.key ? null : entry.key);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected == entry.key ? _green : const Color(0xFFE6EBE6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                entry.value,
                style: textTheme.labelMedium?.copyWith(
                  color: selected == entry.key
                      ? Colors.white
                      : _green.withOpacity(0.8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Short summary of the active filters, for the chip row on the Discover
/// screen ("10 km · Networking").
String discoverFilterSummary(DiscoverFilters f) {
  final parts = <String>[
    if (f.distanceKm != null) '${f.distanceKm} km',
    if (f.purpose != null) purposeLabelFromApi(f.purpose),
    if (f.interest != null)
      '${f.interest![0].toUpperCase()}${f.interest!.substring(1)}',
    if (f.availability != null)
      f.availability == 'THIS_WEEK' ? 'This week' : 'This weekend',
  ]..removeWhere((s) => s.isEmpty);
  return parts.join(' · ');
}
