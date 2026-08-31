import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// Auth endpoints beyond the OTP flow.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// `POST /auth/logout` — revokes the user's refresh tokens server-side so
  /// the session ends on every device, not just this one.
  Future<void> logout() => _client.post('/auth/logout');
}

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});
