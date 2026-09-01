/// Single source of truth for every route path/segment in the app.
/// No screen or widget should reference a route as a raw string literal —
/// always go through a constant or path builder here.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const verify = '/verify';

  static const onboardProfile = '/onboarding/profile';
  static const onboardConversation = '/onboarding/conversation';
  static const onboardCoffee = '/onboarding/coffee';

  /// Post-onboarding success beat that auto-advances into [searching].
  /// Not under `/onboarding/` on purpose — by the time it shows, onboarding
  /// is already marked done and the auth guard would bounce an onboarding
  /// route to /home.
  static const coffeeReady = '/coffee-ready';

  static const home = '/home';
  static const discover = '/discover';
  static const matches = '/matches'; // "Chats" tab
  static const meetings = '/meetings'; // off the nav bar, still routable
  static const profile = '/profile';

  static const editProfile = 'edit';
  static String get editProfilePath => '$profile/$editProfile';

  static const editPreferences = 'preferences';
  static String get editPreferencesPath => '$profile/$editPreferences';

  static const create = '/create';
  static const searching = '/searching';

  static const match = '/match/:matchId';
  static String matchPath(String id) => '/match/$id';

  static const matchDetails = 'details';
  static String matchDetailsPath(String id) => '${matchPath(id)}/$matchDetails';

  static const matchWaiting = 'waiting';
  static String matchWaitingPath(String id) => '${matchPath(id)}/$matchWaiting';

  static const matchConfirmed = 'confirmed';
  static String matchConfirmedPath(String id) =>
      '${matchPath(id)}/$matchConfirmed';

  static const chooseCafe = 'cafes';
  static String chooseCafePath(String id) => '${matchPath(id)}/$chooseCafe';

  static const cafeProposed = 'proposed';
  static String cafeProposedPath(String matchId) =>
      '${chooseCafePath(matchId)}/$cafeProposed';

  static const cafeDetails = ':cafeId';
  static String cafeDetailsPath(String matchId, String cafeId) =>
      '${chooseCafePath(matchId)}/$cafeId';

  static const meetingDetails = '/meeting/:meetingId';
  static String meetingPath(String id) => '/meeting/$id';

  static const meetingConfirmed = 'confirmed';
  static String meetingConfirmedPath(String id) =>
      '${meetingPath(id)}/$meetingConfirmed';

  static const chat = 'chat';
  static String chatPath(String id) => '${meetingPath(id)}/$chat';

  /// Chat opened by match id (from the Chats tab or a resolved meeting).
  static const chatByMatch = '/chat/:matchId';
  static String chatByMatchPath(String matchId) => '/chat/$matchId';

  static const safety = 'safety';
  static String safetyPath(String id) => '${meetingPath(id)}/$safety';

  /// Account-level blocked-users management.
  static const blockedUsers = '/settings/blocked';

  static const feedback = 'feedback';
  static String feedbackPath(String id) => '${meetingPath(id)}/$feedback';

  static const feedbackSent = 'sent';
  static String feedbackSentPath(String id) =>
      '${feedbackPath(id)}/$feedbackSent';

  static const mutualConnection = 'connection';
  static String mutualConnectionPath(String id) =>
      '${meetingPath(id)}/$mutualConnection';

  static const reportUser = '/report/:userId';
  static String reportPath(String id) => '/report/$id';

  /// Mutual connections list + one connection's public profile.
  static const connections = '/connections';
  static const connectionDetail = '/connections/:connectionId';
  static String connectionDetailPath(String id) => '/connections/$id';

  /// A person's public profile opened from Discover ("View Profile").
  static const discoverProfile = '/discover/:userId';
  static String discoverProfilePath(String id) => '/discover/$id';
}
