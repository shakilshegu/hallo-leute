import 'package:poppylo/router/routes.dart';

/// Maps an incoming deep link (push notification tap, universal link, or
/// `coffeemeet://` custom scheme) to the in-app path it should open.
///
/// Pure and side-effect free so it can be unit tested directly against the
/// notification-to-path table, independent of any push-notification SDK or
/// platform plumbing.
///
/// Supports:
///  - https://coffeemeet.app/... and https://www.coffeemeet.app/...
///  - coffeemeet://...
///
/// Returns null when the link doesn't match a known path, so callers can
/// fall back to the app's normal initial location instead of crashing on an
/// unrecognized link.
String? resolveDeepLink(Uri uri) {
  final isHttpsAppLink = uri.scheme == 'https' &&
      (uri.host == 'coffeemeet.app' || uri.host == 'www.coffeemeet.app');
  final isCustomScheme = uri.scheme == 'coffeemeet';
  if (!isHttpsAppLink && !isCustomScheme) return null;

  // For coffeemeet://match/m1, Uri parses "match" as the host and "m1" as
  // the path — unlike https://coffeemeet.app/match/m1, where the host is
  // the domain and "match" is the first path segment. Normalize both shapes
  // into one segment list.
  final segments = [
    if (isCustomScheme && uri.host.isNotEmpty) uri.host,
    ...uri.pathSegments.where((s) => s.isNotEmpty),
  ];
  if (segments.isEmpty) return null;

  switch (segments[0]) {
    case 'match':
      if (segments.length < 2) return null;
      final matchId = segments[1];
      if (segments.length >= 3 && segments[2] == 'confirmed') {
        return AppRoutes.matchConfirmedPath(matchId);
      }
      if (segments.length >= 4 &&
          segments[2] == 'cafes' &&
          segments[3] == 'proposed') {
        return AppRoutes.cafeProposedPath(matchId);
      }
      return AppRoutes.matchPath(matchId);

    case 'meeting':
      if (segments.length < 2) return null;
      final meetingId = segments[1];
      if (segments.length >= 3) {
        switch (segments[2]) {
          case 'confirmed':
            return AppRoutes.meetingConfirmedPath(meetingId);
          case 'feedback':
            return AppRoutes.feedbackPath(meetingId);
          case 'chat':
            return AppRoutes.chatPath(meetingId);
        }
      }
      return AppRoutes.meetingPath(meetingId);
  }

  return null;
}
