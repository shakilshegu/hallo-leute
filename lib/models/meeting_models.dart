enum MeetingStatus { scheduled, completed, cancelled }

class Meeting {
  final String id;
  final String matchId;
  final String partnerName;
  final DateTime startTime;
  final DateTime endTime;
  final MeetingStatus status;
  final bool feedbackSubmitted;

  /// Null until both people have agreed on a café. The meeting guard uses
  /// this to decide whether the café flow still needs to run.
  final String? cafeName;
  final String? cafeAddress;

  const Meeting({
    required this.id,
    required this.matchId,
    required this.partnerName,
    required this.startTime,
    required this.endTime,
    this.status = MeetingStatus.scheduled,
    this.feedbackSubmitted = false,
    this.cafeName,
    this.cafeAddress,
  });

  bool get hasEnded => DateTime.now().isAfter(endTime);

  Meeting copyWith({
    MeetingStatus? status,
    bool? feedbackSubmitted,
    String? cafeName,
    String? cafeAddress,
  }) {
    return Meeting(
      id: id,
      matchId: matchId,
      partnerName: partnerName,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      feedbackSubmitted: feedbackSubmitted ?? this.feedbackSubmitted,
      cafeName: cafeName ?? this.cafeName,
      cafeAddress: cafeAddress ?? this.cafeAddress,
    );
  }
}
