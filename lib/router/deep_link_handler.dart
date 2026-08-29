import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/deep_link_resolver.dart';
import 'package:poppylo/router/routes.dart';

/// Wires incoming https app links (coffeemeet.app) and the `coffeemeet://`
/// custom scheme to [router], via [resolveDeepLink].
///
/// Every link lands on top of `/home` rather than replacing the whole stack,
/// so the back button/gesture always has somewhere sane to go instead of a
/// blank route.
class DeepLinkHandler {
  DeepLinkHandler(this.router) : _appLinks = AppLinks();

  final GoRouter router;
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  Future<void> start() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handle(initialUri);
    } catch (e) {
      debugPrint('[deep_link] failed to read initial link: $e');
    }

    _subscription = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (Object e) => debugPrint('[deep_link] stream error: $e'),
    );
  }

  void _handle(Uri uri) {
    final path = resolveDeepLink(uri);
    if (path == null) {
      debugPrint('[deep_link] ignoring unrecognized link: $uri');
      return;
    }
    router.go(AppRoutes.home);
    if (path != AppRoutes.home) {
      router.push(path);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
