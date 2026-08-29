/// Single source of truth for every route path/segment in the app.
/// No screen or widget should reference a route as a raw string literal —
/// always go through a constant or path builder here.
class AppRoutes {
  AppRoutes._();

  static const splash = '/splash';
  static const welcome = '/welcome';
  static const login = '/login';
  static const emailLogin = 'email';
  static String get emailLoginPath => '$login/$emailLogin';
  static const verify = '/verify';

  static const onboardProfile = '/onboarding/profile';
  static const onboardInterests = '/onboarding/interests';
  static const onboardPurpose = '/onboarding/purpose';
  static const onboardPreferences = '/onboarding/preferences';
  static const onboardNotifications = '/onboarding/notifications';

  static const home = '/home';
  static const matches = '/matches';
  static const meetings = '/meetings';
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

  static const safety = 'safety';
  static String safetyPath(String id) => '${meetingPath(id)}/$safety';

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
}
