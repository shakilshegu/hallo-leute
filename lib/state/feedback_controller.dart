import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/feedback_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/feedback_api.dart';

export 'package:poppylo/services/feedback_api.dart'
    show FeedbackApi, feedbackApiProvider;

/// Whether the current user can leave feedback for a meeting
/// (`GET /meetings/:id/feedback/status`). The backend is the source of truth;
/// screens `ref.watch` this and never decide eligibility locally.
final feedbackStatusProvider =
    FutureProvider.autoDispose.family<FeedbackStatus, String>((ref, meetingId) {
  return ref.watch(feedbackApiProvider).status(meetingId);
});

/// User-facing copy for a failed feedback call.
String feedbackErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You cannot submit feedback for this meeting.';
      case 409:
        return 'Feedback has already been submitted.';
      case 404:
        return 'This meeting is no longer available.';
      case 0:
        return 'Unable to submit feedback. Please try again.';
      case 500:
        return 'Something went wrong. Please try again.';
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}
