import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/auth/auth_service.dart';
import 'data/local_store.dart';
import 'data/progress.dart';
import 'data/remote/backend_config.dart';
import 'data/remote/progress_remote.dart';
import 'data/sync/sync_service.dart';
import 'data/vocabulary.dart';
import 'services/crash_reporting.dart';
import 'services/reminders.dart';

Future<void> main() => CrashReporting.run(_start);

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Vocabulary.load();
  _registerFontLicenses();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0B1830),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  // Progress is saved on the device first; returning learners go straight home.
  final store = PrefsStore.create();
  final progress = await LearningProgress.load(store);
  final profile = await progress.loadProfile();
  final auth = await _connectBackend(store, progress);
  final reminders = Reminders(store);
  await reminders.load();
  runApp(
    HalloLeuteApp(
      progress: progress,
      profile: profile,
      auth: auth,
      reminders: reminders,
    ),
  );
}

/// Connects to Supabase when configured (see BackendConfig). Every learner
/// gets an anonymous guest account, and progress syncs in the background.
/// Returns null for offline-only builds.
Future<AuthService?> _connectBackend(
  KeyValueStore store,
  LearningProgress progress,
) async {
  if (!BackendConfig.isConfigured) return null;
  await Supabase.initialize(
    url: BackendConfig.supabaseUrl,
    publishableKey: BackendConfig.supabasePublishableKey,
  );
  final client = Supabase.instance.client;
  late final AuthService auth;
  final sync = SyncService(
    progress: progress,
    remote: SupabaseProgressRemote(client),
    store: store,
    ensureSession: () => auth.ensureGuest(),
  );
  auth = AuthService(client: client, progress: progress, sync: sync);
  unawaited(sync.start());
  return auth;
}

/// Bundled fonts are SIL OFL 1.1; show their licenses on the licenses page.
void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Fredoka', 'Nunito']) {
      final text = await rootBundle.loadString('assets/licenses/$font-OFL.txt');
      yield LicenseEntryWithLineBreaks([font], text);
    }
  });
}
