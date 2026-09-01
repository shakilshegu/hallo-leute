import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/discover_api.dart';

export 'package:poppylo/services/discover_api.dart'
    show DiscoverApi, discoverApiProvider;

/// The Home / Discover feed, loaded from `GET /home`.
final discoverFeedProvider = FutureProvider<DiscoverFeed>((ref) {
  return ref.watch(discoverApiProvider).getFeed();
});

// --- People discovery (`GET /discover`) --------------------------------

const int _pageSize = 20;

/// Immutable state for the Discover people screen.
@immutable
class DiscoverPeopleState {
  const DiscoverPeopleState({
    this.users = const [],
    this.filters = DiscoverFilters.none,
    this.loading = true,
    this.loadingMore = false,
    this.refreshing = false,
    this.error,
    this.hasNext = false,
    this.page = 0,
    this.emptyMessage,
  });

  final List<DiscoverUser> users;
  final DiscoverFilters filters;
  final bool loading; // first load / after a filter change
  final bool loadingMore; // fetching the next page
  final bool refreshing; // pull-to-refresh in flight
  final Object? error; // first-load / refresh failure
  final bool hasNext;
  final int page; // last page successfully loaded (0 = none yet)
  final String? emptyMessage; // backend message when there are no results

  bool get isEmpty => users.isEmpty && !loading && error == null;

  DiscoverPeopleState copyWith({
    List<DiscoverUser>? users,
    DiscoverFilters? filters,
    bool? loading,
    bool? loadingMore,
    bool? refreshing,
    Object? error,
    bool clearError = false,
    bool? hasNext,
    int? page,
    String? emptyMessage,
    bool clearEmptyMessage = false,
  }) {
    return DiscoverPeopleState(
      users: users ?? this.users,
      filters: filters ?? this.filters,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      refreshing: refreshing ?? this.refreshing,
      error: clearError ? null : (error ?? this.error),
      hasNext: hasNext ?? this.hasNext,
      page: page ?? this.page,
      emptyMessage:
          clearEmptyMessage ? null : (emptyMessage ?? this.emptyMessage),
    );
  }
}

/// Owns the Discover feed: first load, infinite scroll, pull-to-refresh and
/// filter changes. No API calls live in the widgets.
class DiscoverController extends StateNotifier<DiscoverPeopleState> {
  DiscoverController(this._api) : super(const DiscoverPeopleState()) {
    load();
  }

  final DiscoverApi _api;

  Future<void> load() async {
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearEmptyMessage: true,
    );
    await _fetchFirstPage();
  }

  /// Pull-to-refresh — reload from page 1, keeping the current list visible
  /// until the new one arrives.
  Future<void> refresh() async {
    state = state.copyWith(refreshing: true, clearError: true);
    await _fetchFirstPage(refresh: true);
  }

  Future<void> applyFilters(DiscoverFilters filters) async {
    state = state.copyWith(
      filters: filters,
      loading: true,
      users: const [],
      page: 0,
      hasNext: false,
      clearError: true,
      clearEmptyMessage: true,
    );
    await _fetchFirstPage();
  }

  Future<void> loadMore() async {
    if (state.loadingMore || state.refreshing || !state.hasNext) return;
    state = state.copyWith(loadingMore: true);
    try {
      final next = await _api.people(
        page: state.page + 1,
        limit: _pageSize,
        filters: state.filters,
      );
      state = state.copyWith(
        users: [...state.users, ...next.users],
        page: next.page,
        hasNext: next.hasNext,
        loadingMore: false,
      );
    } catch (_) {
      // A failed "load more" shouldn't blow away the list — just stop.
      state = state.copyWith(loadingMore: false);
    }
  }

  Future<void> _fetchFirstPage({bool refresh = false}) async {
    try {
      final first = await _api.people(
        page: 1,
        limit: _pageSize,
        filters: state.filters,
      );
      state = state.copyWith(
        users: first.users,
        page: first.page,
        hasNext: first.hasNext,
        loading: false,
        refreshing: false,
        clearError: true,
        emptyMessage: first.users.isEmpty ? first.message : null,
        clearEmptyMessage: first.users.isNotEmpty,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        refreshing: false,
        // Keep an existing list on a failed refresh; only surface the error
        // when we have nothing to show.
        error: (refresh && state.users.isNotEmpty) ? null : e,
      );
    }
  }
}

final discoverControllerProvider =
    StateNotifierProvider.autoDispose<DiscoverController, DiscoverPeopleState>(
        (ref) {
  return DiscoverController(ref.watch(discoverApiProvider));
});

/// One person's public profile (`GET /discover/:userId`).
final discoverProfileProvider =
    FutureProvider.autoDispose.family<DiscoverUserProfile, String>((ref, id) {
  return ref.watch(discoverApiProvider).profile(id);
});

/// User-facing copy for a failed Discover call.
String discoverErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return "You can't view this right now.";
      case 404:
        return 'This person is no longer available.';
      case 0:
        return 'Check your connection and try again.';
      case 500:
        return 'Something went wrong. Please try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
  return 'Something went wrong. Please try again.';
}

/// The currently selected quick-filter chips (client-side filtering of the
/// sample feed).
final discoverFiltersProvider = StateProvider<Set<DiscoverFilter>>((ref) => {});

/// The feed after the selected filters are applied.
final filteredDiscoverProvider = Provider<AsyncValue<DiscoverFeed>>((ref) {
  final feed = ref.watch(discoverFeedProvider);
  final filters = ref.watch(discoverFiltersProvider);

  return feed.whenData((f) {
    if (filters.isEmpty) return f;
    var meets = f.meets;
    if (filters.contains(DiscoverFilter.today)) {
      meets = meets.where((m) => m.isToday).toList();
    }
    if (filters.contains(DiscoverFilter.thisWeek)) {
      meets = meets.where((m) => m.isThisWeek).toList();
    }
    if (filters.contains(DiscoverFilter.availableNow)) {
      meets = meets.where((m) => m.availableNow).toList();
    }
    if (filters.contains(DiscoverFilter.nearby)) {
      meets = meets.where((m) => m.distanceKm <= 3).toList();
    }
    if (filters.contains(DiscoverFilter.interests)) {
      meets = meets.where((m) => m.sharedInterests.isNotEmpty).toList();
    }
    return DiscoverFeed(
      location: f.location,
      meets: meets,
      nearbyPeople: f.nearbyPeople,
    );
  });
});
