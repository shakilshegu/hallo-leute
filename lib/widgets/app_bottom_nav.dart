import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/home_screen.dart';
import 'package:poppylo/screens/matches_screen.dart';
import 'package:poppylo/screens/meetings_screen.dart';
import 'package:poppylo/screens/profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        HapticFeedback.selectionClick();
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MatchesScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const MeetingsScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        } else if (index == 3) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const ProfileScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
            (route) => false,
          );
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF8F9F8),
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.primary.withOpacity(0.5),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
      unselectedLabelStyle: textTheme.labelSmall,
      elevation: 20,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.coffee_maker_outlined), label: 'Matches'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Meetings'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}
