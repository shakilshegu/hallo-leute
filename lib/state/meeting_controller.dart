import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/models/meeting_models.dart';

/// A synchronous, in-memory cache of the meetings this session has loaded
/// from the backend, so the route guards can read a meeting's real café /
/// feedback state before a screen's async fetch resolves.
///
/// Written only from real `GET /meetings` / `GET /meetings/:id` responses —
/// never seeded with placeholder data. An id that isn't cached yet means
/// "not loaded", and the guards let the screen fetch and render it.
class MeetingRepository extends StateNotifier<Map<String, Meeting>> {
  MeetingRepository() : super(const {});

  /// Replace the cached meeting with a fresh copy from the backend, keeping
  /// any locally-tracked feedback flag.
  void upsert(Meeting meeting) {
    final existing = state[meeting.id];
    state = {
      ...state,
      meeting.id: meeting.copyWith(
        feedbackSubmitted: existing?.feedbackSubmitted,
      ),
    };
  }

  /// Mark the cached meeting's feedback as submitted, right after a
  /// successful `POST /meetings/:id/feedback`. No-op if the meeting isn't
  /// cached (the feedback screen always loads it first).
  void submitFeedback(String id) {
    final meeting = state[id];
    if (meeting == null) return;
    state = {
      ...state,
      id: meeting.copyWith(
        feedbackSubmitted: true,
        status: MeetingStatus.completed,
      ),
    };
  }
}

final meetingRepositoryProvider =
    StateNotifierProvider<MeetingRepository, Map<String, Meeting>>((ref) {
  return MeetingRepository();
});
