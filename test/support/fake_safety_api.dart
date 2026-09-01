import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/models/safety_models.dart';
import 'package:poppylo/services/safety_api.dart';

import 'fake_cafe_api.dart' show sampleMeeting;

/// Scriptable test double for [SafetyApi].
class FakeSafetyApi implements SafetyApi {
  FakeSafetyApi({
    this.reportError,
    this.blockError,
    this.unblockError,
    this.cancelError,
    List<BlockedUser>? blocked,
  }) : blocked = blocked ?? [];

  Object? reportError;
  Object? blockError;
  Object? unblockError;
  Object? cancelError;

  final List<BlockedUser> blocked;

  final List<Map<String, String?>> reports = [];
  final List<String> blockedIds = [];
  final List<String> unblockedIds = [];
  final List<Map<String, String>> cancellations = [];

  @override
  Future<void> reportUser(
    String userId, {
    required String reason,
    String? details,
  }) async {
    if (reportError != null) throw reportError!;
    reports.add({'userId': userId, 'reason': reason, 'details': details});
  }

  @override
  Future<void> blockUser(String userId) async {
    if (blockError != null) throw blockError!;
    blockedIds.add(userId);
  }

  @override
  Future<void> unblockUser(String userId) async {
    if (unblockError != null) throw unblockError!;
    unblockedIds.add(userId);
    blocked.removeWhere((b) => b.id == userId);
  }

  @override
  Future<List<BlockedUser>> blockedUsers() async => List.of(blocked);

  @override
  Future<MeetingDetails> cancelMeeting(
    String meetingId, {
    required String reason,
  }) async {
    if (cancelError != null) throw cancelError!;
    cancellations.add({'meetingId': meetingId, 'reason': reason});
    final base = sampleMeeting(id: meetingId);
    return MeetingDetails(
      id: base.id,
      matchId: base.matchId,
      status: MeetingLifecycle.cancelled,
      date: base.date,
      startTime: base.startTime,
      durationMinutes: base.durationMinutes,
      cafe: base.cafe,
      partner: base.partner,
      createdAt: base.createdAt,
    );
  }
}
