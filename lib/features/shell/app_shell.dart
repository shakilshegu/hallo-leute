import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import 'bloom_dock.dart';

const dockItems = [
  DockItem(icon: Icons.wb_sunny_rounded, german: 'Heute', english: 'Today'),
  DockItem(icon: Icons.style_rounded, german: 'Lernen', english: 'Learn'),
  DockItem(
    icon: Icons.autorenew_rounded,
    german: 'Wiederholen',
    english: 'Review',
  ),
  DockItem(icon: Icons.face_rounded, german: 'Ich', english: 'Me'),
];

/// Main app frame: tab content + the floating Bloom Dock.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewDue = ref.watch(
      homeDataProvider.select((h) => h.value?.reviewDue ?? 0),
    );

    return Scaffold(
      extendBody: true,
      body: shell,
      bottomNavigationBar: BloomDock(
        items: dockItems,
        index: shell.currentIndex,
        badges: {if (reviewDue > 0) 2},
        onSelect: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

/// Cross-fades between tabs while keeping each tab's state alive.
class FadingBranches extends StatelessWidget {
  const FadingBranches({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (final (i, child) in children.indexed)
          IgnorePointer(
            ignoring: i != currentIndex,
            child: AnimatedOpacity(
              opacity: i == currentIndex ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: AnimatedSlide(
                offset: i == currentIndex
                    ? Offset.zero
                    : const Offset(0, 0.015),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                // Pause animations in hidden tabs.
                child: TickerMode(enabled: i == currentIndex, child: child),
              ),
            ),
          ),
      ],
    );
  }
}
