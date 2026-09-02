import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/match_models.dart';

/// A synchronous, in-memory cache of the matches this session has loaded from
/// the backend. It exists only so the route guards — which run synchronously,
/// before a screen's async load resolves — can read a match's real status.
///
/// Every entry is written by [matchDetailsProvider] (and the searching /
/// waiting screens) straight from a real `GET /matches/:id` response. The
/// cache is never seeded or back-filled with placeholder data: an id that
/// isn't here yet simply means "not loaded", and the guards treat it as such.
class MatchRepository extends StateNotifier<Map<String, Match>> {
  MatchRepository() : super(const {});

  /// Replace the cached match with a fresh copy from the backend, preserving
  /// any café already chosen locally.
  void upsert(Match match) {
    final existing = state[match.id];
    state = {
      ...state,
      match.id: match.copyWith(
        cafeId: existing?.cafeId,
        cafeName: existing?.cafeName,
      ),
    };
  }
}

final matchRepositoryProvider =
    StateNotifierProvider<MatchRepository, Map<String, Match>>((ref) {
  return MatchRepository();
});
