import 'package:flutter/foundation.dart';

/// coffee-meet-api feedback contract (see `src/modules/feedback`).

/// Feedback Screen "How did the conversation feel?" label → API
/// `ConversationFeeling` enum value.
const Map<String, String> kConversationFeelingToApi = {
  'GREAT': 'GREAT',
  'GOOD': 'GOOD',
  'OKAY': 'OKAY',
  'NOT GREAT': 'NOT_GOOD',
};

/// Feedback Screen "What stood out?" label → API `FeedbackTag` enum value.
/// Labels with no backend equivalent (e.g. "NOT A GOOD FIT") are simply not
/// sent.
const Map<String, String> kFeedbackTagToApi = {
  'FRIENDLY': 'friendly',
  'INTERESTING': 'interesting',
  'EASY TO TALK TO': 'easy_to_talk_to',
  'GREAT CONVERSATION': 'great_conversation',
};

/// "Would you meet again?" — the backend takes a strict boolean. Only an
/// explicit "YES" counts as wanting to meet again (MAYBE / NO do not, so a
/// mutual connection is only ever formed on a clear YES from both sides).
bool wouldMeetAgainFromLabel(String? label) => label == 'YES';

/// `GET /meetings/:id/feedback/status`.
@immutable
class FeedbackStatus {
  const FeedbackStatus({
    required this.canSubmit,
    required this.submitted,
    this.reason,
  });

  final bool canSubmit;
  final bool submitted;

  /// e.g. `MEETING_NOT_COMPLETED`, `MEETING_CANCELLED`. Null when [canSubmit].
  final String? reason;

  factory FeedbackStatus.fromJson(Map<String, dynamic> json) {
    return FeedbackStatus(
      canSubmit: json['canSubmit'] as bool? ?? false,
      submitted: json['submitted'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }

  static const unavailable = FeedbackStatus(canSubmit: false, submitted: false);
}

/// The `POST /meetings/:id/feedback` response. Deliberately carries no hint of
/// the other person's answer — only whether a mutual connection now exists.
@immutable
class SubmitFeedbackResult {
  const SubmitFeedbackResult({
    required this.mutualConnectionCreated,
    this.connectionId,
  });

  final bool mutualConnectionCreated;
  final String? connectionId;

  factory SubmitFeedbackResult.fromJson(Map<String, dynamic> json) {
    final mc = json['mutualConnection'] as Map<String, dynamic>? ?? const {};
    return SubmitFeedbackResult(
      mutualConnectionCreated: mc['created'] as bool? ?? false,
      connectionId: mc['id'] as String?,
    );
  }
}
