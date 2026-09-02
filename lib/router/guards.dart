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

const _preAuthRoutes = {
  AppRoutes.welcome,
  AppRoutes.login,
  AppRoutes.verify,
};

String _onboardingStepPath(OnboardingStep step) {
  switch (step) {
    case OnboardingStep.profile:
      return AppRoutes.onboardProfile;
    case OnboardingStep.conversation:
      return AppRoutes.onboardConversation;
    case OnboardingStep.coffee:
      return AppRoutes.onboardCoffee;
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
      return isOnboardingRoute
          ? null
          : _onboardingStepPath(auth.onboardingStep);
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

    // Unknown meeting → let the screen load it; don't bounce on a placeholder.
    final meeting = ref.read(meetingRepositoryProvider)[meetingId];
    if (meeting == null) return null;

    // A backend Meeting row only exists once the match is CONFIRMED, so if we
    // don't have the match cached we trust that and let chat open. Only bounce
    // when we positively know the match isn't accepted yet.
    final match = ref.read(matchRepositoryProvider)[meeting.matchId];
    if (match != null && !match.status.isAtLeast(MatchStatus.accepted)) {
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

    // No cached match (opened cold / deep link) or one that isn't confirmed
    // yet → send the user to match details, which loads the real status.
    final match = ref.read(matchRepositoryProvider)[matchId];
    if (match == null || match.status != MatchStatus.confirmed) {
      return AppRoutes.matchDetailsPath(matchId);
    }
    return null;
  };
});

/// 4. Meeting guard: any /meeting/:meetingId route requires a café to
/// already be agreed; otherwise send the user back into the café flow.
///
/// A real `Meeting` row only exists on the backend *after* a café is agreed,
/// so an id the repository hasn't seen yet is assumed valid — the screen
/// fetches it and renders its own loading / error state. We only bounce when
/// we positively know (from a cached copy) that the café is still missing.
final meetingGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    final meetingId = state.pathParameters['meetingId'];
    if (meetingId == null || !state.matchedLocation.startsWith('/meeting/')) {
      return null;
    }

    final meeting = ref.read(meetingRepositoryProvider)[meetingId];
    if (meeting != null && meeting.cafeName == null) {
      return AppRoutes.chooseCafePath(meeting.matchId);
    }
    return null;
  };
});

/// 5. Feedback guard: once feedback is submitted, keep the user out of the
/// form (send them to the "sent" screen instead). Eligibility itself
/// (meeting ended / not cancelled) is the backend's call — `FeedbackScreen`
/// reads `GET /feedback/status` and the "Leave feedback" entry point is only
/// shown when the backend says `canSubmit`.
final feedbackGuardProvider = Provider<GuardFn>((ref) {
  return (context, state) {
    if (!state.matchedLocation.endsWith('/${AppRoutes.feedback}')) {
      return null;
    }
    final meetingId = state.pathParameters['meetingId'];
    if (meetingId == null) return null;

    final meeting = ref.read(meetingRepositoryProvider)[meetingId];
    if (meeting != null && meeting.feedbackSubmitted) {
      return AppRoutes.feedbackSentPath(meetingId);
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

    // Only act on a match we've actually loaded and know to be terminal.
    final match = ref.read(matchRepositoryProvider)[matchId];
    if (match == null || !match.status.isTerminal) return null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            match.status == MatchStatus.expired
                ? 'Sorry, this match has expired.'
                : '${match.partnerName} passed on this match.',
          ),
        ),
      );
    });
    return AppRoutes.home;
  };
});
