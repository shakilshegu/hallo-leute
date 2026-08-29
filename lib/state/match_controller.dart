import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/match_models.dart';

Match _placeholderMatch(String id) => Match(
      id: id,
      partnerName: 'Sarah',
      status: MatchStatus.proposed,
      proposedTime: DateTime.now().add(const Duration(hours: 6)),
    );

class MatchRepository extends StateNotifier<Map<String, Match>> {
  MatchRepository() : super(_seed());

  static Map<String, Match> _seed() {
    return {
      'demo-match': Match(
        id: 'demo-match',
        partnerName: 'Sarah',
        status: MatchStatus.proposed,
        proposedTime: DateTime.now().add(const Duration(hours: 6)),
      ),
    };
  }

  Match _ensure(String id) => state[id] ?? _placeholderMatch(id);

  void setStatus(String id, MatchStatus status) {
    final match = _ensure(id);
    state = {...state, id: match.copyWith(status: status)};
  }

  /// Both parties have now accepted the match.
  void accept(String id) => setStatus(id, MatchStatus.confirmed);

  void decline(String id) => setStatus(id, MatchStatus.declined);

  void expire(String id) => setStatus(id, MatchStatus.expired);

  void proposeCafe(String id, String cafeId, String cafeName) {
    final match = _ensure(id);
    state = {
      ...state,
      id: match.copyWith(cafeId: cafeId, cafeName: cafeName),
    };
  }
}

final matchRepositoryProvider =
    StateNotifierProvider<MatchRepository, Map<String, Match>>((ref) {
  return MatchRepository();
});

/// Read-only lookup for a single match, synthesizing a sensible default for
/// ids the repository hasn't seen yet (e.g. opened straight from a deep
/// link). Pure — never mutates the repository, so it's safe to call from
/// guards and widget builds alike.
final matchProvider = Provider.family<Match, String>((ref, id) {
  final matches = ref.watch(matchRepositoryProvider);
  return matches[id] ?? _placeholderMatch(id);
});
