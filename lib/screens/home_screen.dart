import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/location_service.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;
import 'package:poppylo/services/profile_api.dart';
import 'package:poppylo/state/discover_controller.dart';
import 'package:poppylo/state/profile_controller.dart';
import 'package:poppylo/widgets/coffee_meet_card.dart';
import 'package:poppylo/widgets/nearby_person_card.dart';
import 'package:poppylo/services/notification_service.dart';

const _green = Color(0xFF1B3B2B);
const _bg = Color(0xFFF3F1EB);

/// Home / Discover — the first screen after onboarding. Personalised header
/// from `/users/me`; the discovery feed is realistic sample data (matching
/// has no backend yet).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _lastBackPress;
  bool _hasUnreadNotifications = true;
  bool _savingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Push notifications are best-effort — never let a plugin/Firebase
      // hiccup (or a test environment) break the home screen.
      try {
        final apiClient = ref.read(apiClientProvider);
        final ns = NotificationService();
        await ns.initialize(apiClient);
        await ns.requestPermissionAndSyncToken();
      } catch (_) {}
    });
  }

  // Coarse coordinates so a manual city pick still gives the backend a point
  // to sort distance by (a device fix from "Use my location" is exact).
  static const _cities = <String, (double, double)>{
    'Kochi, India': (9.9312, 76.2673),
    'Bengaluru, India': (12.9716, 77.5946),
    'Mumbai, India': (19.076, 72.8777),
    'Chennai, India': (13.0827, 80.2707),
    'Hyderabad, India': (17.385, 78.4867),
    'Pune, India': (18.5204, 73.8567),
  };

  String get _partOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _handleBack() async {
    final now = DateTime.now();
    if (_lastBackPress != null &&
        now.difference(_lastBackPress!) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Press back again to exit'),
        duration: Duration(seconds: 2),
      ));
  }

  void _openCreate() {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.create);
  }

  Future<void> _changeLocation() async {
    HapticFeedback.selectionClick();
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.my_location, color: _green),
                title: const Text('Use my current location'),
                onTap: () => Navigator.pop(ctx, '__gps__'),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'OR PICK A CITY',
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                          color: _green.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              for (final c in _cities.keys)
                ListTile(
                  leading:
                      const Icon(Icons.location_on_outlined, color: _green),
                  title: Text(c),
                  onTap: () => Navigator.pop(ctx, c),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;
    if (choice == '__gps__') {
      await _useDeviceLocation();
    } else {
      final coords = _cities[choice]!;
      await _saveLocation(coords.$1, coords.$2, choice);
    }
  }

  Future<void> _useDeviceLocation() async {
    setState(() => _savingLocation = true);
    try {
      final place = await ref.read(locationServiceProvider).currentPlace();
      await _saveLocation(place.latitude, place.longitude, place.name);
    } on LocationDenied catch (e) {
      if (mounted) _snack(e.message);
    } catch (_) {
      if (mounted) _snack("Couldn't get your location. Try again.");
    } finally {
      if (mounted) setState(() => _savingLocation = false);
    }
  }

  Future<void> _saveLocation(double lat, double lng, String name) async {
    try {
      await ref.read(profileApiProvider).updateProfile(
            latitude: lat,
            longitude: lng,
            locationName: name,
          );
      ref.invalidate(meProvider);
      ref.invalidate(discoverFeedProvider);
      if (mounted) _snack('Location set to $name');
    } on ApiException catch (e) {
      if (mounted) _snack("Couldn't save your location (${e.message}).");
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(m)));
  }

  void _viewMeet(CoffeeMeet meet) {
    HapticFeedback.lightImpact();
    context.push(AppRoutes.matchPath(meet.id));
  }

  void _viewPerson(NearbyPerson person) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _green.withOpacity(0.08),
                backgroundImage: NetworkImage(person.avatarUrl),
              ),
              const SizedBox(height: 14),
              Text(
                person.name,
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      color: _green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatDistance(person.distanceKm)} away',
                style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                      color: _green.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: [
                  for (final t in person.interestTags)
                    Chip(
                      label: Text(t),
                      backgroundColor: _green.withOpacity(0.06),
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openCreate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Invite for a coffee'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(meProvider);
    final firstName = me.maybeWhen(
      data: (d) => d.profile?.firstName,
      orElse: () => null,
    );
    final photoUrl = me.maybeWhen(
      data: (d) => d.profile?.photoUrl,
      orElse: () => null,
    );
    final greeting = (firstName != null && firstName.isNotEmpty)
        ? '$_partOfDay, $firstName'
        : _partOfDay;

    final filtered = ref.watch(filteredDiscoverProvider);
    final activeFilters = ref.watch(discoverFiltersProvider);

    final savedLocation = me.maybeWhen(
      data: (d) => d.profile?.locationName,
      orElse: () => null,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: _green,
            onRefresh: () async {
              ref.invalidate(discoverFeedProvider);
              await ref.read(discoverFeedProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _Header(
                  greeting: greeting,
                  photoUrl: photoUrl,
                  hasUnread: _hasUnreadNotifications,
                  onBell: () => setState(() => _hasUnreadNotifications = false),
                  onMeetings: () => context.push(AppRoutes.meetings),
                ),
                const SizedBox(height: 14),
                _LocationRow(
                  location: savedLocation,
                  busy: _savingLocation,
                  onChange: _changeLocation,
                ),
                const SizedBox(height: 20),
                _Hero(onFind: _openCreate),
                const SizedBox(height: 24),
                _FilterChips(
                  active: activeFilters,
                  onToggle: (f) {
                    HapticFeedback.selectionClick();
                    final next = {...activeFilters};
                    next.contains(f) ? next.remove(f) : next.add(f);
                    ref.read(discoverFiltersProvider.notifier).state = next;
                  },
                ),
                const SizedBox(height: 24),
                filtered.when(
                  loading: () => const _LoadingList(),
                  error: (_, __) => _ErrorCard(
                    onRetry: () => ref.invalidate(discoverFeedProvider),
                  ),
                  data: (f) {
                    if (f.meets.isEmpty) {
                      return _EmptyState(
                        filtered: activeFilters.isNotEmpty,
                        onClearFilters: () => ref
                            .read(discoverFiltersProvider.notifier)
                            .state = {},
                        onCreate: _openCreate,
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: 'Recommended for you',
                          subtitle: 'Based on your interests and preferences',
                        ),
                        const SizedBox(height: 16),
                        for (final meet in f.meets) ...[
                          CoffeeMeetCard(
                              meet: meet, onView: () => _viewMeet(meet)),
                          const SizedBox(height: 14),
                        ],
                        if (f.nearbyPeople.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'People nearby'),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 244,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              itemCount: f.nearbyPeople.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) => NearbyPersonCard(
                                person: f.nearbyPeople[i],
                                onViewProfile: () =>
                                    _viewPerson(f.nearbyPeople[i]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.photoUrl,
    required this.hasUnread,
    required this.onBell,
    required this.onMeetings,
  });

  final String greeting;
  final String? photoUrl;
  final bool hasUnread;
  final VoidCallback onBell;
  final VoidCallback onMeetings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineSmall?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Ready for a good conversation?',
                style: textTheme.bodySmall?.copyWith(
                  color: _green.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onMeetings,
          tooltip: 'Your coffee meetings',
          icon: const Icon(Icons.calendar_today_outlined, color: _green),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: onBell,
              icon: const Icon(Icons.notifications_none, color: _green),
            ),
            if (hasUnread)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE89A00),
                    shape: BoxShape.circle,
                    border: Border.all(color: _bg, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 18,
          backgroundColor: _green.withOpacity(0.1),
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? const Icon(Icons.person, size: 20, color: _green)
              : null,
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.location,
    required this.busy,
    required this.onChange,
  });

  final String? location;
  final bool busy;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasLocation = (location ?? '').isNotEmpty;

    return GestureDetector(
      onTap: busy ? null : onChange,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(hasLocation ? Icons.location_on : Icons.location_off_outlined,
              size: 16, color: _green),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              busy
                  ? 'Getting your location…'
                  : hasLocation
                      ? location!
                      : 'Set your location',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            )
          else
            Text(
              hasLocation ? 'Change' : 'Enable',
              style: textTheme.labelSmall?.copyWith(
                color: _green.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onFind});
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Find someone to share a coffee with.',
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Meet interesting people nearby over a simple cup of coffee.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onFind,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE89A00),
                foregroundColor: _green,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Find a Coffee Meet',
                style: textTheme.titleMedium?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.active, required this.onToggle});

  final Set<DiscoverFilter> active;
  final ValueChanged<DiscoverFilter> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: DiscoverFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = DiscoverFilter.values[i];
          final selected = active.contains(f);
          return GestureDetector(
            onTap: () => onToggle(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _green : Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: selected ? _green : _green.withOpacity(0.12),
                ),
              ),
              child: Text(
                f.label,
                style: textTheme.labelSmall?.copyWith(
                  color: selected ? Colors.white : _green.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: _green,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              color: _green.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    Widget skeleton(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _green.withOpacity(0.3),
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recommended for you',
          subtitle: 'Based on your interests and preferences',
        ),
        const SizedBox(height: 16),
        skeleton(180),
        skeleton(180),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded,
              color: _green.withOpacity(0.7), size: 34),
          const SizedBox(height: 12),
          Text(
            "Couldn't load coffee meets",
            style: textTheme.titleSmall?.copyWith(color: _green),
          ),
          const SizedBox(height: 4),
          Text(
            'Check your connection and try again.',
            style:
                textTheme.bodySmall?.copyWith(color: _green.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: BorderSide(color: _green.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.filtered,
    required this.onClearFilters,
    required this.onCreate,
  });

  final bool filtered;
  final VoidCallback onClearFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_cafe_outlined,
                color: _green.withOpacity(0.6), size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'No coffee meets nearby yet',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            filtered
                ? 'No meets match these filters. Try clearing a few, '
                    'or create your own.'
                : 'Try expanding your search or create your own meet.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: _green.withOpacity(0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onCreate,
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Create a Meet'),
            ),
          ),
          if (filtered) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClearFilters,
              child: Text(
                'Clear filters',
                style: textTheme.bodySmall?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
