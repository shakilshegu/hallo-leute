import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/screens/splash_screen.dart';
import 'package:poppylo/services/onboarding_api.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/theme/app_theme.dart';
import 'package:poppylo/router/app_router.dart';
import 'package:poppylo/router/deep_link_handler.dart';

import 'package:poppylo/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Register background handler early
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  DeepLinkHandler? _deepLinkHandler;

  /// Cold-start login runs before the router mounts so the auth guard sees the
  /// restored session on its first evaluation instead of bouncing to Welcome.
  /// Capped so a slow/cold backend can't leave the user staring at the splash —
  /// `restoreSession` sets an optimistic signed-in state immediately, and the
  /// router re-runs its guards once the backend sync finishes in the background.
  late final Future<void> _bootstrap = ref
      .read(authControllerProvider.notifier)
      .restoreSession(ref.read(onboardingApiProvider))
      .timeout(const Duration(seconds: 5), onTimeout: () {});

  @override
  void dispose() {
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            home: const SplashScreen(),
          );
        }

        final router = ref.watch(routerProvider);
        _deepLinkHandler ??= DeepLinkHandler(router)..start();

        return MaterialApp.router(
          title: 'Coffee Meet',
          theme: AppTheme.lightTheme,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
