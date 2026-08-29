import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Logs every route change in debug builds as `previous -> next`, so the
/// full navigation flow (guards included) can be verified from the console.
class RouteLoggerObserver extends NavigatorObserver {
  String? _lastPath;

  void _log(Route<dynamic>? route) {
    if (!kDebugMode) return;
    final path = route?.settings.name;
    if (path == null || path == _lastPath) return;
    debugPrint('[router] ${_lastPath ?? '(none)'} -> $path');
    _lastPath = path;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _log(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _log(newRoute);
}
