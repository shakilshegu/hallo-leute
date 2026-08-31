import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/services/profile_api.dart';

/// The signed-in user's own profile aggregate (`GET /users/me`).
///
/// The Profile tab watches this; the edit screens call the API then
/// `ref.invalidate(meProvider)` so the tab reflects the change on return.
final meProvider = FutureProvider<UserMe>((ref) {
  return ref.watch(profileApiProvider).getMe();
});
