import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/database.dart';
import 'data/providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await db.seedWords(
    await rootBundle.loadString('assets/words/starter_words.json'),
  );
  final profile = await db.getProfile();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      // Returning learners skip welcome + onboarding.
      child: PoppyloApp(
        initialLocation: profile == null ? Routes.welcome : Routes.home,
      ),
    ),
  );
}

class PoppyloApp extends StatefulWidget {
  const PoppyloApp({super.key, this.initialLocation = Routes.welcome});

  final String initialLocation;

  @override
  State<PoppyloApp> createState() => _PoppyloAppState();
}

class _PoppyloAppState extends State<PoppyloApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Poppylo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
