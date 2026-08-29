import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/auth_models.dart';
import 'package:poppylo/models/match_models.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/match_controller.dart';
import 'package:poppylo/state/meeting_controller.dart';
import 'routes.dart';

typedef GuardFn = String? Function(BuildContext context, GoRouterState state);

final _preAuthRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.emailLoginPath,
  AppRoutes.verify,
};

String _onboardingStepPath(OnboardingStep step) {
  switch (step) {
    case OnboardingStep.profile:
      return AppRoutes.onboardProfile;
    case OnboardingStep.interests:
      return AppRoutes.onboardInterests;
    case OnboardingStep.purpose:
      return AppRoutes.onboardPurpose;
    case OnboardingStep.preferences:
      return AppRoutes.onboardPreferences;
    case OnboardingStep.notifications:
      return AppRoutes.onboardNotifications;
    case OnboardingStep.done:
      return AppRoutes.home;
  }
}

/// 1. Auth guard: signed-out users are confined to the pre-auth routes,
/// signed-in-but-incomplete users are confined to onboarding, and finishing
/// either sends you on to /home.
final authGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    final auth = ref.read(authControllerProvider);
    final path = state.matchedLocation;

    if (path == AppRoutes.splash) {
      if (!auth.isSignedIn) return AppRoutes.welcome;
      if (!auth.isOnboardingComplete) {
        return _onboardingStepPath(auth.onboardingStep);
      }
      return AppRoutes.home;
    }

    final isOnboardingRoute = path.startsWith('/onboarding/');

    if (!auth.isSignedIn) {
      return _preAuthRoutes.contains(path) ? null : AppRoutes.welcome;
    }

    if (!auth.isOnboardingComplete) {
      return isOnboardingRoute ? null : _onboardingStepPath(auth.onboardingStep);
    }

    if (_preAuthRoutes.contains(path) || isOnboardingRoute) {
      return AppRoutes.home;
    }

    return null;
  };
});

/// 2. Chat guard: messaging is impossible until both people have accepted
/// the match (status accepted or later).
final chatGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    if (!state.matchedLocation.endsWith('/${AppRoutes.chat}')) return null;
    final meetingId = state.pathParameters['meetingId'];
    if (meetingId == null) return null;

    final meeting = ref.read(meetingProvider(meetingId));
    final match = ref.read(matchProvider(meeting.matchId));
    if (!match.status.isAtLeast(MatchStatus.accepted)) {
      return AppRoutes.matchDetailsPath(meeting.matchId);
    }
    return null;
  };
});

/// 3. Café guard: the café flow only opens once both people have accepted
/// the match (status confirmed).
final cafeGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    if (!state.matchedLocation.contains('/${AppRoutes.chooseCafe}')) {
      return null;
    }
    final matchId = state.pathParameters['matchId'];
    if (matchId == null) return null;

    final match = ref.read(matchProvider(matchId));
    if (match.status != MatchStatus.confirmed) {
      return AppRoutes.matchDetailsPath(matchId);
    }
    return null;
  };
});

/// 4. Meeting guard: any /meeting/:meetingId route requires a café to
/// already be agreed; otherwise send the user back into the café flow.
final meetingGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    final meetingId = state.pathParameters['meetingId'];
    if (meetingId == null || !state.matchedLocation.startsWith('/meeting/')) {
      return null;
    }

    final meeting = ref.read(meetingProvider(meetingId));
    if (meeting.cafeName == null) {
      return AppRoutes.chooseCafePath(meeting.matchId);
    }
    return null;
  };
});

/// 5. Feedback guard: feedback can only be given after the meeting has
/// ended, and only once.
final feedbackGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    if (!state.matchedLocation.endsWith('/${AppRoutes.feedback}')) {
      return null;
    }
    final meetingId = state.pathParameters['meetingId'];
    if (meetingId == null) return null;

    final meeting = ref.read(meetingProvider(meetingId));
    if (meeting.feedbackSubmitted) {
      return AppRoutes.feedbackSentPath(meetingId);
    }
    if (!meeting.hasEnded) {
      return AppRoutes.meetingPath(meetingId);
    }
    return null;
  };
});

/// 6. Stale match guard: bounce out of a match (and its whole sub-stack)
/// the moment it expires or gets declined, with an explanation.
final staleMatchGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    if (!state.matchedLocation.startsWith('/match/')) return null;
    final matchId = state.pathParameters['matchId'];
    if (matchId == null) return null;

    final match = ref.read(matchProvider(matchId));
    if (!match.status.isTerminal) return null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            match.status == MatchStatus.expired
                ? 'That match expired.'
                : 'Sarah passed on this match.',
          ),
        ),
      );
    });
    return AppRoutes.home;
  };
});
