import 'package:poppylo/models/matching_models.dart';
import 'package:poppylo/services/matching_api.dart';

MatchProfile _sampleProfile({
  String id = 'user-2',
  String name = 'Ben',
  List<String> interests = const ['Travel', 'Technology'],
}) {
  return MatchProfile(
    id: id,
    name: name,
    age: 29,
    photoUrl: null,
    job: 'Barista',
    bio: 'Flat white enthusiast.',
    interests: interests,
  );
}

MatchDetails sampleMatch({
  String id = 'match-1',
  int score = 84,
  MatchLifecycle status = MatchLifecycle.pending,
  MatchResponseStatus myResponse = MatchResponseStatus.pending,
  MatchResponseStatus otherResponse = MatchResponseStatus.pending,
  List<String> whyMatched = const [
    'You both like Travel and Technology',
    'You are 1.2 km apart',
  ],
  MatchProfile? user,
}) {
  return MatchDetails(
    id: id,
    score: score,
    status: status,
    myResponse: myResponse,
    otherResponse: otherResponse,
    whyMatched: whyMatched,
    date: '2026-09-05',
    startTime: '17:00',
    durationMinutes: 45,
    user: user ?? _sampleProfile(),
  );
}

MatchStatusResult matchFoundResult(MatchDetails match) =>
    MatchStatusResult.fromJson({
      'status': 'MATCH_FOUND',
      'match': {
        'id': match.id,
        'score': match.score,
        'status': _statusWire(match.status),
        'myResponse': _respWire(match.myResponse),
        'otherResponse': _respWire(match.otherResponse),
        'whyMatched': match.whyMatched,
        'date': match.date,
        'startTime': match.startTime,
        'durationMinutes': match.durationMinutes,
        'user': {
          'id': match.user.id,
          'name': match.user.name,
          'age': match.user.age,
          'profileImage': match.user.photoUrl,
          'job': match.user.job,
          'bio': match.user.bio,
          'interests': match.user.interests,
        },
      },
    });

MatchStatusResult searchingResult({String requestId = 'r1', String? message}) =>
    MatchStatusResult.fromJson({
      'status': 'SEARCHING',
      'requestId': requestId,
      'message': message ?? "We're looking for someone who matches you.",
    });

String _statusWire(MatchLifecycle s) => switch (s) {
      MatchLifecycle.pending => 'PENDING',
      MatchLifecycle.acceptedByOne => 'ACCEPTED_BY_ONE',
      MatchLifecycle.confirmed => 'CONFIRMED',
      MatchLifecycle.declined => 'DECLINED',
      MatchLifecycle.expired => 'EXPIRED',
      MatchLifecycle.unknown => 'PENDING',
    };

String _respWire(MatchResponseStatus s) => switch (s) {
      MatchResponseStatus.accepted => 'ACCEPTED',
      MatchResponseStatus.declined => 'DECLINED',
      _ => 'PENDING',
    };

/// Scriptable test double for [MatchingApi].
class FakeMatchingApi implements MatchingApi {
  FakeMatchingApi({
    this.startResult,
    this.statusResult,
    this.matchDetail,
    this.statusError,
    this.matchError,
  });

  MatchStatusResult? startResult;
  MatchStatusResult? statusResult;
  MatchDetails? matchDetail;
  Object? statusError;
  Object? matchError;

  /// Overrides the result of `accept()` (defaults to `matchDetail` with
  /// `myResponse = accepted`).
  MatchDetails? acceptResult;
  MatchDetails? passResult;

  int startCalls = 0;
  int pollCalls = 0;
  int getCalls = 0;
  int acceptCalls = 0;
  int passCalls = 0;

  @override
  Future<MatchStatusResult> startMatching(String requestId) async {
    startCalls++;
    if (statusError != null) throw statusError!;
    return startResult ?? statusResult ?? searchingResult(requestId: requestId);
  }

  @override
  Future<MatchStatusResult> pollStatus(String requestId) async {
    pollCalls++;
    if (statusError != null) throw statusError!;
    return statusResult ?? searchingResult(requestId: requestId);
  }

  @override
  Future<MatchDetails> getMatch(String matchId) async {
    getCalls++;
    if (matchError != null) throw matchError!;
    return matchDetail ?? sampleMatch(id: matchId);
  }

  @override
  Future<MatchDetails> accept(String matchId) async {
    acceptCalls++;
    if (matchError != null) throw matchError!;
    return acceptResult ??
        sampleMatch(
          id: matchId,
          status: MatchLifecycle.acceptedByOne,
          myResponse: MatchResponseStatus.accepted,
        );
  }

  @override
  Future<MatchDetails> pass(String matchId) async {
    passCalls++;
    if (matchError != null) throw matchError!;
    return passResult ??
        sampleMatch(
          id: matchId,
          status: MatchLifecycle.declined,
          myResponse: MatchResponseStatus.declined,
        );
  }
}
