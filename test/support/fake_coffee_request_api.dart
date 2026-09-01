import 'package:poppylo/models/coffee_request_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/coffee_request_api.dart';

/// Test double for [CoffeeRequestApi]. Records the last `create` payload and
/// lets a test script the responses (including thrown [ApiException]s).
class FakeCoffeeRequestApi implements CoffeeRequestApi {
  FakeCoffeeRequestApi({this.active});

  CoffeeRequest? active;
  Map<String, Object?>? lastCreatePayload;
  int cancelCalls = 0;

  /// When set, `create` throws this instead of returning.
  Object? createError;

  /// When set, `getById` returns this (otherwise a PENDING sample).
  CoffeeRequest? detail;

  /// When set, `getById` throws this.
  Object? detailError;

  CoffeeRequest sample({
    String id = 'req-new',
    CoffeeRequestStatus status = CoffeeRequestStatus.pending,
  }) =>
      _sample(id: id, status: status);

  CoffeeRequest _sample({
    String id = 'req-new',
    CoffeeRequestStatus status = CoffeeRequestStatus.pending,
  }) {
    return CoffeeRequest(
      id: id,
      status: status,
      date: '2026-09-01',
      startTime: '15:00',
      durationMinutes: 45,
      maxDistanceKm: 10,
      purpose: 'friends',
      conversationStyle: 'deep',
      expiresAt: DateTime.utc(2026, 9, 1, 15),
    );
  }

  @override
  Future<CoffeeRequest> create({
    required String date,
    required String startTime,
    required int durationMinutes,
    required int maxDistanceKm,
    required String purpose,
    required String conversationStyle,
  }) async {
    lastCreatePayload = {
      'date': date,
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      'maxDistanceKm': maxDistanceKm,
      'purpose': purpose,
      'conversationStyle': conversationStyle,
    };
    if (createError != null) throw createError!;
    return _sample();
  }

  @override
  Future<CoffeeRequest?> getActive() async => active;

  @override
  Future<CoffeeRequest> getById(String id) async {
    if (detailError != null) throw detailError!;
    return detail ?? _sample(id: id);
  }

  @override
  Future<CoffeeRequest> cancel(String id) async {
    cancelCalls++;
    active = null;
    return _sample(id: id, status: CoffeeRequestStatus.cancelled);
  }
}
