import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Pill selection state for the Find someone card
  String _selectedPill = 'Today 5 PM';
  final List<String> _timePills = [
    'Today 5 PM',
    'Tomorrow 11 AM',
    'Pick a time'
  ];
  DateTime? _lastBackPress;

  void _startCreateMeet() {
    HapticFeedback.mediumImpact();
    context.push(AppRoutes.create);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=150&auto=format&fit=crop'),
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
                  'Good morning, Aisha',
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

                      // Time Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _timePills.map((time) {
                            final isSelected = time == _selectedPill;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedPill = time);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.5)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    time,
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                                context.push(AppRoutes.chatPath('demo'));
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

                // Who's Free This Week
                _buildSectionHeader(
                    'WHO\'S FREE THIS WEEK', null, textTheme, colorScheme),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFreeCard(
                          'SAT 5 PM', '12 PEOPLE FREE', colorScheme, textTheme),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFreeCard(
                          'SUN 11 AM', '8 PEOPLE FREE', colorScheme, textTheme),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Cafés Near You
                _buildSectionHeader(
                    'CAFÉS NEAR YOU', 'See all', textTheme, colorScheme),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      _buildCafeCard(
                        'Brew Lab',
                        '4.6 • 1.2 KM • QUIET',
                        'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=400&auto=format&fit=crop',
                        colorScheme,
                        textTheme,
                      ),
                      const SizedBox(width: 16),
                      _buildCafeCard(
                        'The Daily Grind',
                        '4.4 • 2.5 KM • LIVELY',
                        'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?q=80&w=400&auto=format&fit=crop',
                        colorScheme,
                        textTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Today's Starter
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5ECE4), // Light greenish-grey
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY\'S STARTER',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '"What\'s something you\'ve been really into lately?"',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: colorScheme.primary.withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          'Another one',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // People You've Met
                _buildSectionHeader(
                    'PEOPLE YOU\'VE MET', null, textTheme, colorScheme),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 120, // Enough for 4 overlapping avatars
                        height: 40,
                        child: Stack(
                          children: [
                            _buildOverlappingAvatar(0,
                                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
                            _buildOverlappingAvatar(1,
                                'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop'),
                            _buildOverlappingAvatar(2,
                                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop'),
                            _buildOverlappingAvatar(3,
                                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop'),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'See all connections',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Bottom Trust Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildTrustBadge(Icons.verified_outlined, 'Photo verified',
                        colorScheme, textTheme),
                    _buildTrustBadge(Icons.storefront_outlined, 'Partner cafes',
                        colorScheme, textTheme),
                    _buildTrustBadge(Icons.access_time, 'You choose',
                        colorScheme, textTheme),
                  ],
                ),
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

  Widget _buildFreeCard(
      String time, String count, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.6),
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCafeCard(String name, String details, String imageUrl,
      ColorScheme colorScheme, TextTheme textTheme) {
    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlappingAvatar(int index, String imageUrl) {
    return Positioned(
      left: index * 24.0,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(imageUrl),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label, ColorScheme colorScheme,
      TextTheme textTheme) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary.withOpacity(0.5), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
