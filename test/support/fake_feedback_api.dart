import 'package:poppylo/models/feedback_models.dart';
import 'package:poppylo/services/feedback_api.dart';

/// Scriptable test double for [FeedbackApi].
class FakeFeedbackApi implements FeedbackApi {
  FakeFeedbackApi({
    this.statusResult = const FeedbackStatus(canSubmit: true, submitted: false),
    this.submitResult =
        const SubmitFeedbackResult(mutualConnectionCreated: false),
    this.submitError,
  });

  FeedbackStatus statusResult;
  SubmitFeedbackResult submitResult;
  Object? submitError;

  final List<Map<String, Object?>> submissions = [];

  @override
  Future<FeedbackStatus> status(String meetingId) async => statusResult;

  @override
  Future<SubmitFeedbackResult> submit(
    String meetingId, {
    required int rating,
    required String conversationFeeling,
    required bool wouldMeetAgain,
    List<String> tags = const [],
    String? comment,
  }) async {
    submissions.add({
      'meetingId': meetingId,
      'rating': rating,
      'conversationFeeling': conversationFeeling,
      'wouldMeetAgain': wouldMeetAgain,
      'tags': tags,
      'comment': comment,
    });
    if (submitError != null) throw submitError!;
    return submitResult;
  }
}
