import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_info.dart';

/// One "Rate & suggest" message from a learner.
class FeedbackEntry {
  const FeedbackEntry({required this.rating, this.improve, this.likes});

  /// 1–5 stars.
  final int rating;

  /// "What could be better?"
  final String? improve;

  /// "What do you like?"
  final String? likes;

  /// Row for `public.feedback`; blank answers are stored as null.
  Map<String, Object?> toRow({
    required String appVersion,
    required String platform,
  }) => {
    'rating': rating,
    'improve': _clean(improve),
    'likes': _clean(likes),
    'app_version': appVersion,
    'platform': platform,
  };

  static String? _clean(String? text) {
    final t = text?.trim() ?? '';
    return t.isEmpty ? null : t;
  }
}

/// Sends feedback to the server.
abstract class FeedbackRemote {
  Future<void> send(FeedbackEntry entry);
}

/// Inserts into `public.feedback` (insert-only for learners, see the
/// 20261121120000_feedback migration). Makes sure the learner has a
/// session first, so guests who were offline at onboarding can still send.
class SupabaseFeedbackRemote implements FeedbackRemote {
  SupabaseFeedbackRemote(
    SupabaseClient client, {
    required this.ensureSession,
    @visibleForTesting Future<void> Function(Map<String, Object?> row)? insert,
  }) : _insert = insert ?? ((row) => client.from('feedback').insert(row));

  /// Creates the guest account when there is no session yet.
  final Future<void> Function() ensureSession;
  final Future<void> Function(Map<String, Object?> row) _insert;

  @override
  Future<void> send(FeedbackEntry entry) async {
    await ensureSession();
    await _insert(
      entry.toRow(
        appVersion: AppInfo.version,
        platform: defaultTargetPlatform.name,
      ),
    );
  }
}
