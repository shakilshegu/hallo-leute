import 'package:poppylo/models/connection_models.dart';
import 'package:poppylo/services/connection_api.dart';

ConnectionUser sampleConnectionUser({
  String id = 'u2',
  String name = 'Ben',
  double? rating = 4.8,
  String? bio,
  String? job,
}) =>
    ConnectionUser(
      id: id,
      name: name,
      profileImage: null,
      averageRating: rating,
      bio: bio,
      job: job,
    );

/// Scriptable test double for [ConnectionApi].
class FakeConnectionApi implements ConnectionApi {
  FakeConnectionApi({
    List<Connection>? list,
    this.detail,
    this.listError,
    this.detailError,
  }) : list = list ?? [];

  List<Connection> list;
  Connection? detail;
  Object? listError;
  Object? detailError;

  @override
  Future<List<Connection>> connections() async {
    if (listError != null) throw listError!;
    return list;
  }

  @override
  Future<Connection> connection(String connectionId) async {
    if (detailError != null) throw detailError!;
    return detail ??
        Connection(
          id: connectionId,
          user: sampleConnectionUser(bio: 'Hi', job: 'Dev'),
          createdAt: DateTime.utc(2026, 9, 1),
          meetingId: 'm1',
        );
  }
}
