import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _selectedTabIndex = 0; // 0 for ACTIVE, 1 for PAST

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryColor = const Color(0xFF1D3D33); // Dark green
    final bgColor = const Color(0xFFF3F1EB); // Base app background

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'MATCHES • 4 ACTIVE',
                  style: textTheme.labelSmall?.copyWith(
                    color: primaryColor.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
                Row(
                  children: [
                    _buildTabHeader('Active', _selectedTabIndex == 0,
                        primaryColor, textTheme, () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = 0);
                    }),
                    const SizedBox(width: 16),
                    _buildTabHeader(
                        'Past', _selectedTabIndex == 1, primaryColor, textTheme,
                        () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedTabIndex = 1);
                    }),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_selectedTabIndex == 0) ...[
              // Active Tab Content

              // Main Action Card
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    height: 380,
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                        bottom: 28), // space for overlapping pill
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      image: const DecorationImage(
                        image: NetworkImage(
                            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.5, 1.0],
                        ),
                      ),
                      child: Column(
                        children: [
                          const Spacer(),
                          // Text content at bottom
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEEDS YOUR ANSWER',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withOpacity(0.7),
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sarah, 27',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Product designer',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      '2.1 KM • SAT 5:00 PM • 45 MIN',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: Colors.white.withOpacity(0.6),
                                        letterSpacing: 1.0,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.more_horiz,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 20),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Floating Action Pill
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {},
                            borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(28)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              child: Text(
                                'Pass',
                                style: textTheme.titleSmall?.copyWith(
                                  color: primaryColor.withOpacity(0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                right: 4, top: 4, bottom: 4),
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              child: Text(
                                'Accept',
                                style: textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // EVERYTHING ELSE section
              Text(
                'EVERYTHING ELSE',
                style: textTheme.labelSmall?.copyWith(
                  color: primaryColor.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 8),

              _buildListRow(
                context,
                index: '01',
                name: 'Priya',
                subtitle: 'SENT 2H AGO',
                status: 'WAITING',
                statusColor: primaryColor.withOpacity(0.5),
                imageUrl:
                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150&auto=format&fit=crop',
                primaryColor: primaryColor,
                textTheme: textTheme,
              ),
              _buildDivider(primaryColor),
              _buildListRow(
                context,
                index: '02',
                name: 'Meera',
                subtitle: 'SUN 11:00 AM',
                status: 'Choose café',
                statusColor: const Color(0xFFE0A008), // Yellow
                imageUrl:
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop',
                primaryColor: primaryColor,
                textTheme: textTheme,
              ),
              _buildDivider(primaryColor),
              _buildListRow(
                context,
                index: '03',
                name: 'Sarah',
                subtitle: 'SAT 5 PM • BREW LAB',
                status: 'CONFIRMED',
                statusColor: primaryColor,
                hasDot: true,
                imageUrl:
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop',
                primaryColor: primaryColor,
                textTheme: textTheme,
              ),
              _buildDivider(primaryColor),
              _buildListRow(
                context,
                index: '04',
                name: 'Anjali',
                subtitle: 'EXPIRED 1D AGO',
                status: 'GONE',
                statusColor: primaryColor.withOpacity(0.3),
                imageUrl:
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop', // A grayscale image ideally, but we'll use opacity
                primaryColor: primaryColor,
                textTheme: textTheme,
                isFaded: true,
              ),

              const SizedBox(height: 32),

              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  'Find another match',
                  style: textTheme.titleSmall?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // PAST Tab Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(
                    'No past matches yet',
                    style: textTheme.titleMedium?.copyWith(
                      color: primaryColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildTabHeader(String label, bool isSelected, Color primaryColor,
      TextTheme textTheme, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: isSelected ? primaryColor : primaryColor.withOpacity(0.5),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2,
              width: label.length * 8.0,
              color: primaryColor,
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildListRow(
    BuildContext context, {
    required String index,
    required String name,
    required String subtitle,
    required String status,
    required Color statusColor,
    required String imageUrl,
    required Color primaryColor,
    required TextTheme textTheme,
    bool hasDot = false,
    bool isFaded = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Opacity(
        opacity: isFaded ? 0.5 : 1.0,
        child: Row(
          children: [
            Text(
              index,
              style: textTheme.labelSmall?.copyWith(
                color: primaryColor.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.labelSmall?.copyWith(
                      color: primaryColor.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  status,
                  style: textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                if (hasDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0A008), // Yellow
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color primaryColor) {
    return Divider(
      height: 1,
      thickness: 1,
      color: primaryColor.withOpacity(0.05),
    );
  }
}
