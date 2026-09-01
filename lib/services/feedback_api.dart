import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/feedback_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/meetings/:id/feedback*`. The data layer for the
/// post-meeting feedback flow — screens go through this via providers, never
/// [ApiClient] directly. The Firebase ID token is attached automatically.
class FeedbackApi {
  FeedbackApi(this._client);

  final ApiClient _client;

  /// `GET /meetings/:meetingId/feedback/status` — the backend is the source
  /// of truth for whether feedback can be left.
  Future<FeedbackStatus> status(String meetingId) async {
    final data = await _client.get('/meetings/$meetingId/feedback/status');
    return FeedbackStatus.fromJson(data);
  }

  /// `POST /meetings/:meetingId/feedback`. No user ids in the body — the
  /// backend resolves author + subject itself.
  Future<SubmitFeedbackResult> submit(
    String meetingId, {
    required int rating,
    required String conversationFeeling, // API enum value
    required bool wouldMeetAgain,
    List<String> tags = const [], // API enum values
    String? comment,
  }) async {
    final data = await _client.post(
      '/meetings/$meetingId/feedback',
      body: {
        'rating': rating,
        'conversationFeeling': conversationFeeling,
        'wouldMeetAgain': wouldMeetAgain,
        if (tags.isNotEmpty) 'tags': tags,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return SubmitFeedbackResult.fromJson(data);
  }
}

final feedbackApiProvider = Provider<FeedbackApi>((ref) {
  return FeedbackApi(ref.watch(apiClientProvider));
});
