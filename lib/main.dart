import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/theme/app_theme.dart';
import 'package:poppylo/router/app_router.dart';
import 'package:poppylo/router/deep_link_handler.dart';

void main() {
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

  @override
  void dispose() {
    _deepLinkHandler?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    if (_deepLinkHandler == null) {
      _deepLinkHandler = DeepLinkHandler(router);
      _deepLinkHandler!.start();
    }

    return MaterialApp.router(
      title: 'Coffee Meet',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
