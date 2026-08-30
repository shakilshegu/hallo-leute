import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/meeting_models.dart';

Meeting _placeholderMeeting(String id) {
  final now = DateTime.now();
  return Meeting(
    id: id,
    matchId: 'demo-match',
    partnerName: 'Sarah',
    startTime: now,
    endTime: now.add(const Duration(minutes: 45)),
  );
}

class MeetingRepository extends StateNotifier<Map<String, Meeting>> {
  MeetingRepository() : super(_seed());

  static Map<String, Meeting> _seed() {
    final now = DateTime.now();
    return {
      'demo-meeting': Meeting(
        id: 'demo-meeting',
        matchId: 'demo-match',
        partnerName: 'Sarah',
        cafeName: 'Brew Lab',
        cafeAddress: '1.2 km away',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 2, minutes: 45)),
      ),
    };
  }

  Meeting _ensure(String id) => state[id] ?? _placeholderMeeting(id);

  /// Called once both people have agreed on a café and time, creating (or
  /// updating) the meeting tied to [matchId].
  void confirm(
    String meetingId,
    String matchId, {
    required String cafeName,
    required String partnerName,
    required DateTime startTime,
    String? cafeAddress,
    Duration duration = const Duration(minutes: 45),
  }) {
    state = {
      ...state,
      meetingId: Meeting(
        id: meetingId,
        matchId: matchId,
        partnerName: partnerName,
        cafeName: cafeName,
        cafeAddress: cafeAddress,
        startTime: startTime,
        endTime: startTime.add(duration),
      ),
    };
  }

  void submitFeedback(String id) {
    final meeting = _ensure(id);
    state = {
      ...state,
      id: meeting.copyWith(
        feedbackSubmitted: true,
        status: MeetingStatus.completed,
      ),
    };
  }

  void cancel(String id) {
    final meeting = _ensure(id);
    state = {...state, id: meeting.copyWith(status: MeetingStatus.cancelled)};
  }
}

final meetingRepositoryProvider =
    StateNotifierProvider<MeetingRepository, Map<String, Meeting>>((ref) {
  return MeetingRepository();
});

/// Read-only lookup for a single meeting, synthesizing a placeholder (café
/// not yet agreed) for ids the repository hasn't seen yet. Pure — safe to
/// call from guards and widget builds.
final meetingProvider = Provider.family<Meeting, String>((ref, id) {
  final meetings = ref.watch(meetingRepositoryProvider);
  return meetings[id] ?? _placeholderMeeting(id);
});
