import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/profile_controller.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  DateTime? _lastBackPress;

  void _startCreateMeet() {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.create);
  }

  String get _partOfDay {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final me = ref.watch(meProvider);
    final firstName = me.maybeWhen(
      data: (d) => d.profile?.firstName,
      orElse: () => null,
    );
    final photoUrl = me.maybeWhen(
      data: (d) => d.profile?.photoUrl,
      orElse: () => null,
    );
    final greeting = (firstName != null && firstName.isNotEmpty)
        ? '$_partOfDay, $firstName'
        : _partOfDay;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final now = DateTime.now();
        final canExit = _lastBackPress != null &&
            now.difference(_lastBackPress!) < const Duration(seconds: 2);
        if (canExit) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPress = now;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
            ),
          );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F1EB), // Base app color
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Coffee Meet',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: colorScheme.primary),
              onPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.primary.withOpacity(0.1),
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Icon(Icons.person, size: 18, color: colorScheme.primary)
                    : null,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Text(
                  greeting,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for a good conversation?',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                // Stats Row
                Row(
                  children: [
                    _buildStat('12 COFFEE MEETS', textTheme, colorScheme),
                    _buildStatDot(colorScheme),
                    _buildStat('5 CONNECTIONS', textTheme, colorScheme),
                    _buildStatDot(colorScheme),
                    _buildStat('4.8 AVG', textTheme, colorScheme),
                  ],
                ),
                const SizedBox(height: 24),

                // Main Action Card (Find someone for coffee)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B3B2B), // Dark green
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONNECTION AWAITS',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Find someone for\ncoffee',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Find Match Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _startCreateMeet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFFE89A00), // Yellow/Orange
                            foregroundColor: colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Find my match',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary, // Dark text
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Upcoming Coffee
                _buildSectionHeader(
                    'UPCOMING COFFEE', 'See all', textTheme, colorScheme),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sarah, 27',
                                      style: textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0D4),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CONFIRMED',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: const Color(0xFFD97706),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 9,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'SAT 5:00 PM • BREW LAB • 1.2 KM',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.primary.withOpacity(0.6),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F1EB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'STARTS IN 2H 30M',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                    color:
                                        colorScheme.primary.withOpacity(0.2)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Get directions',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context
                                    .push(AppRoutes.chatPath('demo-meeting'));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE2E8DF),
                                foregroundColor: colorScheme.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                'Message',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String text, TextTheme textTheme, ColorScheme colorScheme) {
    return Text(
      text,
      style: textTheme.labelSmall?.copyWith(
        color: colorScheme.primary.withOpacity(0.6),
        fontWeight: FontWeight.bold,
        fontSize: 9,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildStatDot(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String? action, TextTheme textTheme,
      ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.6),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: () {},
            child: Text(
              action,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
