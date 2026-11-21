import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Crash and error reports to Sentry (EU region).
///
/// The DSN comes from `env.json` like the other keys. Reports are sent only
/// from release builds, so testing on your own phone adds no noise. To check
/// the setup from a debug build, run once with `--dart-define=SENTRY_TEST=true`:
/// it reports even in debug and sends one test event at start-up.
///
/// No personal data is sent: no email, name or IP address.
abstract final class CrashReporting {
  static const dsn = String.fromEnvironment('SENTRY_DSN');
  static const _test = bool.fromEnvironment('SENTRY_TEST');

  static bool get enabled => dsn.isNotEmpty && (kReleaseMode || _test);

  /// Runs the app, with Sentry catching errors when [enabled].
  static Future<void> run(FutureOr<void> Function() appRunner) async {
    if (!enabled) return appRunner();
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.sendDefaultPii = false;
      // Errors only, no performance tracing (keeps within the free plan).
      options.tracesSampleRate = 0;
    }, appRunner: appRunner);
    if (_test) {
      await Sentry.captureMessage('Hallo Leute: Sentry test event');
    }
  }
}
