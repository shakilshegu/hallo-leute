import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';
import 'package:poppylo/state/matching_controller.dart';
import 'package:poppylo/widgets/cafe_photo.dart';

const _bg = Color(0xFFF9F8F5);
const _ink = Color(0xFF2B4739);

class ChooseCafeScreen extends ConsumerStatefulWidget {
  final String matchId;
  const ChooseCafeScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChooseCafeScreen> createState() => _ChooseCafeScreenState();
}

class _ChooseCafeScreenState extends ConsumerState<ChooseCafeScreen> {
  bool _suggesting = false;

  Future<void> _suggest(NearbyCafe cafe) async {
    if (_suggesting) return;
    setState(() => _suggesting = true);
    try {
      final match = await ref.read(matchDetailsProvider(widget.matchId).future);
      await ref.read(cafeApiProvider).suggestCafe(
            widget.matchId,
            placeId: cafe.placeId,
            date: match.date,
            startTime: match.startTime,
          );
      ref.invalidate(cafeSuggestionProvider(widget.matchId));
      if (!mounted) return;
      context.push(AppRoutes.cafeProposedPath(widget.matchId));
    } catch (e) {
      if (!mounted) return;
      _snack(cafeErrorMessage(e));
    } finally {
      if (mounted) setState(() => _suggesting = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final state = ref.watch(nearbyCafesControllerProvider);
    final controller = ref.read(nearbyCafesControllerProvider.notifier);
    final suggestion =
        ref.watch(cafeSuggestionProvider(widget.matchId)).valueOrNull;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Coffee Meet',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Choose a coffee spot ☕',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pick a convenient place to meet.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          if (state.origin != null) _LocationChip(name: state.origin!.name),
          if (state.origin != null) const SizedBox(height: 20),
          if (suggestion != null &&
              !suggestion.isAccepted &&
              !suggestion.isDeclined)
            _suggestionBanner(context, suggestion, textTheme),
          _body(state, controller),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _body(NearbyCafesState state, NearbyCafesController controller) {
    switch (state.phase) {
      case NearbyCafesPhase.locating:
        return const _Status(
          icon: Icons.my_location,
          title: 'Getting your location…',
        );
      case NearbyCafesPhase.loading:
        return const _Status(
          icon: Icons.local_cafe_outlined,
          title: 'Finding nearby coffee spots…',
        );
      case NearbyCafesPhase.gpsOff:
        return _withFallback(
          controller,
          _Status(
            icon: Icons.location_disabled,
            title: 'Location is turned off',
            message: state.message,
            actionLabel: 'Try again',
            onAction: controller.retry,
          ),
        );
      case NearbyCafesPhase.locationDenied:
        return _withFallback(
          controller,
          _Status(
            icon: Icons.location_off_outlined,
            title: 'Location needed',
            message: state.message ??
                'Location permission is needed to find nearby coffee spots.',
            actionLabel: 'Enable location',
            onAction: controller.retry,
          ),
        );
      case NearbyCafesPhase.locationUnavailable:
        return _withFallback(
          controller,
          _Status(
            icon: Icons.location_searching,
            title: "Couldn't get your location",
            message: state.message ??
                "We couldn't get a location fix. Please try again.",
            actionLabel: 'Try again',
            onAction: controller.retry,
          ),
        );
      case NearbyCafesPhase.locationBlocked:
        return _withFallback(
          controller,
          _Status(
            icon: Icons.location_off_outlined,
            title: 'Location is blocked',
            message:
                'Enable location for Coffee Meet in Settings, then try again.',
            actionLabel: 'Open settings',
            onAction: () => Geolocator.openAppSettings(),
            secondaryLabel: 'Try again',
            onSecondary: controller.retry,
          ),
        );
      case NearbyCafesPhase.error:
        return _Status(
          icon: Icons.wifi_off_rounded,
          title: "Couldn't load nearby coffee shops",
          message: state.message,
          actionLabel: 'Try again',
          onAction: controller.retry,
        );
      case NearbyCafesPhase.empty:
        return _Status(
          icon: Icons.local_cafe_outlined,
          title: 'No coffee spots found nearby',
          message:
              state.canExpandRadius ? null : 'Try again from a different spot.',
          actionLabel: state.canExpandRadius
              ? 'Search within ${state.nextRadiusMeters ~/ 1000} km'
              : 'Try again',
          onAction: state.canExpandRadius
              ? controller.expandRadius
              : controller.retry,
        );
      case NearbyCafesPhase.ready:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final cafe in state.cafes) ...[
              _CafeCard(
                matchId: widget.matchId,
                cafe: cafe,
                suggesting: _suggesting,
                onSelect: () => _suggest(cafe),
              ),
              const SizedBox(height: 16),
            ],
            if (state.canExpandRadius)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton.icon(
                  onPressed: controller.expandRadius,
                  icon: const Icon(Icons.travel_explore, size: 18),
                  label: Text(
                    'Search within ${state.nextRadiusMeters ~/ 1000} km',
                  ),
                  style: TextButton.styleFrom(foregroundColor: _ink),
                ),
              ),
          ],
        );
    }
  }

  Widget _withFallback(NearbyCafesController controller, Widget status) {
    return Column(
      children: [
        status,
        const SizedBox(height: 8),
        _LocationFallback(
          onSearch: controller.useTypedLocation,
          onCity: controller.useCoords,
        ),
      ],
    );
  }

  Widget _suggestionBanner(
    BuildContext context,
    CafeSuggestion s,
    TextTheme textTheme,
  ) {
    final mine = s.suggestedBy.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE6D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mine
                ? 'You suggested ${s.cafe.name}'
                : '${s.suggestedBy.name} suggested ${s.cafe.name}',
            style: textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold, color: _ink),
          ),
          const SizedBox(height: 4),
          Text(
            formatSlotDateTime(s.date, s.startTime),
            style: textTheme.bodySmall?.copyWith(color: _ink.withOpacity(0.7)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  context.push(AppRoutes.cafeProposedPath(widget.matchId)),
              style: TextButton.styleFrom(
                foregroundColor: _ink,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(mine ? 'View suggestion' : 'Review & accept'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _ink.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 15, color: _ink),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Near $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: _ink.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Manual "search by area" fallback shown when the device can't give a fix.
class _LocationFallback extends StatefulWidget {
  const _LocationFallback({required this.onSearch, required this.onCity});

  final ValueChanged<String> onSearch;
  final void Function(double lat, double lng, String name) onCity;

  static const _demoCities = <String, (double, double)>{
    'Berlin': (52.5200, 13.4050),
    'Munich': (48.1374, 11.5755),
  };

  @override
  State<_LocationFallback> createState() => _LocationFallbackState();
}

class _LocationFallbackState extends State<_LocationFallback> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      FocusScope.of(context).unfocus();
      widget.onSearch(q);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          'Or search by area',
          style: textTheme.labelMedium?.copyWith(color: _ink.withOpacity(0.6)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'Type a city or address…',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _ink.withOpacity(0.12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: _ink.withOpacity(0.12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _submit,
              style: IconButton.styleFrom(backgroundColor: _ink),
              icon: const Icon(Icons.arrow_forward, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in _LocationFallback._demoCities.entries)
              ActionChip(
                label: Text(entry.key),
                onPressed: () => widget.onCity(
                  entry.value.$1,
                  entry.value.$2,
                  entry.key,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: _ink.withOpacity(0.12)),
                labelStyle: TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final loading = onAction == null && message == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          if (loading)
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
            )
          else
            Icon(icon, size: 34, color: _ink.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium
                ?.copyWith(color: _ink, fontWeight: FontWeight.bold),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: _ink.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
          if (secondaryLabel != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onSecondary,
              style: TextButton.styleFrom(foregroundColor: _ink),
              child: Text(secondaryLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Warm café card — same visual language, real Google data.
class _CafeCard extends StatelessWidget {
  const _CafeCard({
    required this.matchId,
    required this.cafe,
    required this.suggesting,
    required this.onSelect,
  });

  final String matchId;
  final NearbyCafe cafe;
  final bool suggesting;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(AppRoutes.cafeDetailsPath(matchId, cafe.placeId));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EAE1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CafePhoto(proxyPath: cafe.photoUrl, width: 96, height: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cafe.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (cafe.rating != null)
                    Row(
                      children: [
                        Text(cafe.rating!.toStringAsFixed(1),
                            style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.75))),
                        Icon(Icons.star,
                            size: 12,
                            color: colorScheme.primary.withOpacity(0.75)),
                        if (cafe.reviewCount != null)
                          Text('  ·  ${cafe.reviewCount} reviews',
                              style: textTheme.labelSmall?.copyWith(
                                  color: colorScheme.primary.withOpacity(0.6))),
                      ],
                    ),
                  if (cafe.distanceText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(cafe.distanceText,
                        style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary.withOpacity(0.6))),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    cafe.address,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (cafe.openLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      cafe.openLabel!,
                      style: textTheme.labelSmall?.copyWith(
                        color: cafe.isOpen == true
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFB03A2E),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: suggesting ? null : onSelect,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8DF),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.black.withOpacity(0.05)),
                      ),
                      child: Text(
                        suggesting ? 'Sending…' : 'Select',
                        style: textTheme.labelSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
