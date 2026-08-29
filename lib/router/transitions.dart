import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The app's single page-transition vocabulary: slide-from-right for normal
/// pushed routes, fade for full-screen states (Searching, Match found).
/// Shell tab switches get their own fade-through in [AppShell].
CustomTransitionPage<T> slideFromRightPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

CustomTransitionPage<T> fadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

/// Wraps a [GoRoute]'s `builder` as a `pageBuilder` using [slideFromRightPage].
Page<void> Function(BuildContext, GoRouterState) slideBuilder(
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return (context, state) => slideFromRightPage(
        key: state.pageKey,
        child: builder(context, state),
      );
}

/// Wraps a [GoRoute]'s `builder` as a `pageBuilder` using [fadePage].
Page<void> Function(BuildContext, GoRouterState) fadeBuilder(
  Widget Function(BuildContext, GoRouterState) builder,
) {
  return (context, state) => fadePage(
        key: state.pageKey,
        child: builder(context, state),
      );
}
