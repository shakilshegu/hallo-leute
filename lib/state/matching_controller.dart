import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/match_models.dart';
import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/matching_api.dart';
import 'package:poppylo/state/match_controller.dart';

export 'package:poppylo/services/matching_api.dart'
    show MatchingApi, matchingApiProvider;

/// A single match, fetched from `GET /matches/:id`. Every load also refreshes
/// the synchronous [matchRepositoryProvider] cache that the route guards read,
/// so the café / stale-match guards see the real backend status.
final matchDetailsProvider =
    FutureProvider.family<MatchDetails, String>((ref, matchId) async {
  final details = await ref.watch(matchingApiProvider).getMatch(matchId);
  ref.read(matchRepositoryProvider.notifier).upsert(matchFromDetails(details));
  return details;
});

/// Maps the backend `MatchView` onto the guard-facing [Match] model.
Match matchFromDetails(MatchDetails d) {
  return Match(
    id: d.id,
    partnerName: d.user.name,
    status: _guardStatus(d.status),
    proposedTime: _parseSlot(d.date, d.startTime),
  );
}

MatchStatus _guardStatus(MatchLifecycle status) {
  switch (status) {
    case MatchLifecycle.pending:
    case MatchLifecycle.unknown:
      return MatchStatus.proposed;
    case MatchLifecycle.acceptedByOne:
      return MatchStatus.accepted;
    case MatchLifecycle.confirmed:
      return MatchStatus.confirmed;
    case MatchLifecycle.declined:
      return MatchStatus.declined;
    case MatchLifecycle.expired:
      return MatchStatus.expired;
  }
}

DateTime _parseSlot(String date, String startTime) {
  final parsed = DateTime.tryParse('${date}T$startTime:00');
  return parsed ?? DateTime.now().add(const Duration(hours: 4));
}

/// User-facing copy for a failed matching call. Statuses like `expired` are
/// handled as states by the screens, not routed through here.
String matchingErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 404:
        return 'Match no longer exists.';
      case 409:
        return 'Your match has already been updated.';
      case 0:
        return 'Unable to connect. Please try again.';
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}
