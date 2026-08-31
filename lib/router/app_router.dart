import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import 'guards.dart';
import 'transitions.dart';
import 'route_logger.dart';
import 'app_shell.dart';

import '../screens/splash_screen.dart';
import '../screens/welcome_screen.dart';
import '../screens/get_started_screen.dart';
import '../screens/verify_code_screen.dart';
import '../screens/build_profile_screen.dart';
import '../screens/conversation_prefs_screen.dart';
import '../screens/coffee_prefs_screen.dart';
import '../screens/profile_ready_screen.dart';

import '../screens/home_screen.dart';
import '../screens/matches_screen.dart';
import '../screens/meetings_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/edit_preferences_screen.dart';

import '../screens/create_coffee_meet_screen.dart';
import '../screens/searching_screen.dart';
import '../screens/match_found_screen.dart';
import '../screens/match_detail_screen.dart';
import '../screens/waiting_screen.dart';
import '../screens/match_confirmed_screen.dart';
import '../screens/choose_cafe_screen.dart';
import '../screens/cafe_suggested_screen.dart';
import '../screens/cafe_details_screen.dart';

import '../screens/meeting_details_screen.dart';
import '../screens/meeting_confirmed_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/safety_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/feedback_sent_screen.dart';
import '../screens/mutual_connection_screen.dart';
import '../screens/report_user_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorMatchesKey =
    GlobalKey<NavigatorState>(debugLabel: 'matches');
final _shellNavigatorMeetingsKey =
    GlobalKey<NavigatorState>(debugLabel: 'meetings');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

final routerProvider = Provider<GoRouter>((ref) {
  final authGuard = ref.watch(authGuardProvider);
  final chatGuard = ref.watch(chatGuardProvider);
  final cafeGuard = ref.watch(cafeGuardProvider);
  final meetingGuard = ref.watch(meetingGuardProvider);
  final feedbackGuard = ref.watch(feedbackGuardProvider);
  final staleMatchGuard = ref.watch(staleMatchGuardProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    observers: [RouteLoggerObserver()],
    redirect: (context, state) {
      return authGuard(context, state) ??
          chatGuard(context, state) ??
          cafeGuard(context, state) ??
          meetingGuard(context, state) ??
          feedbackGuard(context, state) ??
          staleMatchGuard(context, state);
    },
    errorBuilder: (context, state) => _NotFoundScreen(path: state.uri.path),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: fadeBuilder((c, s) => const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        pageBuilder: slideBuilder((c, s) => const WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: slideBuilder((c, s) {
          final extra = s.extra as Map<String, dynamic>? ?? {};
          final isNewUser = extra['isNewUser'] as bool? ?? false;
          return GetStartedScreen(isNewUser: isNewUser);
        }),
      ),
      GoRoute(
        path: AppRoutes.verify,
        pageBuilder: slideBuilder((c, s) => const VerifyCodeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardProfile,
        pageBuilder: slideBuilder((c, s) => const BuildProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardConversation,
        pageBuilder: slideBuilder((c, s) => const ConversationPrefsScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardCoffee,
        pageBuilder: slideBuilder((c, s) => const CoffeePrefsScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMatchesKey,
            routes: [
              GoRoute(
                path: AppRoutes.matches,
                builder: (context, state) => const MatchesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMeetingsKey,
            routes: [
              GoRoute(
                path: AppRoutes.meetings,
                builder: (context, state) => const MeetingsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // --- Full screen, pushed above the shell (no bottom nav) ---
      GoRoute(
        path: AppRoutes.editProfilePath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: slideBuilder((c, s) => const EditProfileScreen()),
      ),
      GoRoute(
        path: AppRoutes.editPreferencesPath,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: slideBuilder((c, s) => const EditPreferencesScreen()),
      ),
      GoRoute(
        path: AppRoutes.create,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: slideBuilder((c, s) => const CreateCoffeeMeetScreen()),
      ),
      GoRoute(
        path: AppRoutes.coffeeReady,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: fadeBuilder((c, s) => const ProfileReadyScreen()),
      ),
      GoRoute(
        path: AppRoutes.searching,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: fadeBuilder((c, s) => const SearchingScreen()),
      ),
      GoRoute(
        path: AppRoutes.match,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: fadeBuilder(
          (c, s) => MatchFoundScreen(matchId: s.pathParameters['matchId']!),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.matchDetails,
            pageBuilder: slideBuilder(
              (c, s) =>
                  MatchDetailScreen(matchId: s.pathParameters['matchId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.matchWaiting,
            pageBuilder: slideBuilder(
              (c, s) =>
                  MatchStatusScreen(matchId: s.pathParameters['matchId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.matchConfirmed,
            pageBuilder: fadeBuilder(
              (c, s) =>
                  MatchConfirmedScreen(matchId: s.pathParameters['matchId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.chooseCafe,
            pageBuilder: slideBuilder(
              (c, s) => ChooseCafeScreen(matchId: s.pathParameters['matchId']!),
            ),
            routes: [
              GoRoute(
                path: AppRoutes.cafeProposed,
                pageBuilder: fadeBuilder(
                  (c, s) => CafeSuggestedScreen(
                    matchId: s.pathParameters['matchId']!,
                  ),
                ),
              ),
              GoRoute(
                path: AppRoutes.cafeDetails,
                pageBuilder: slideBuilder(
                  (c, s) => CafeDetailsScreen(
                    matchId: s.pathParameters['matchId']!,
                    cafeId: s.pathParameters['cafeId']!,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.meetingDetails,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: slideBuilder(
          (c, s) =>
              MeetingDetailsScreen(meetingId: s.pathParameters['meetingId']!),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.meetingConfirmed,
            pageBuilder: fadeBuilder(
              (c, s) => MeetingConfirmedScreen(
                meetingId: s.pathParameters['meetingId']!,
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.chat,
            pageBuilder: slideBuilder(
              (c, s) => ChatScreen(meetingId: s.pathParameters['meetingId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.safety,
            pageBuilder: slideBuilder(
              (c, s) => SafetyScreen(meetingId: s.pathParameters['meetingId']!),
            ),
          ),
          GoRoute(
            path: AppRoutes.feedback,
            pageBuilder: slideBuilder(
              (c, s) =>
                  FeedbackScreen(meetingId: s.pathParameters['meetingId']!),
            ),
            routes: [
              GoRoute(
                path: AppRoutes.feedbackSent,
                pageBuilder: slideBuilder(
                  (c, s) => FeedbackSentScreen(
                    meetingId: s.pathParameters['meetingId']!,
                  ),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.mutualConnection,
            pageBuilder: fadeBuilder(
              (c, s) => MutualConnectionScreen(
                meetingId: s.pathParameters['meetingId']!,
              ),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.reportUser,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: slideBuilder(
          (c, s) => ReportUserScreen(userId: s.pathParameters['userId']!),
        ),
      ),
    ],
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.explore_off_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  "We couldn't find that page",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  path,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Go home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
