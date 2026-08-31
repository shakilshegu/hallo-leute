import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/router/routes.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  int _selectedTabIndex = 0; // 0 for Upcoming, 1 for Past
  bool _isEmpty = false; // Set to true to show empty state
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'), // User avatar mock
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab row on left
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTabHeader('UPCOMING', _selectedTabIndex == 0,
                    colorScheme.primary, textTheme, () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 0);
                }),
                const SizedBox(width: 24),
                _buildTabHeader('PAST', _selectedTabIndex == 1,
                    colorScheme.primary, textTheme, () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTabIndex = 1);
                }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Content
          Expanded(
            child: _isEmpty
                ? _buildEmptyState(context)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    children: _selectedTabIndex == 0
                        ? [
                            // UPCOMING MEETINGS
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image with badge
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(24)),
                                        child: Image.network(
                                          'https://images.unsplash.com/photo-1497935586351-b67a49e012bf?q=80&w=600&auto=format&fit=crop', // Cafe image
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'CONFIRMED',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SAT 5:00 PM • BREW LAB • 45 MIN',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.primary
                                                .withOpacity(0.5),
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 20,
                                              backgroundImage: NetworkImage(
                                                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop'), // Sarah
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Sarah',
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Coffee enthusiast & designer',
                                                    style: textTheme.bodySmall
                                                        ?.copyWith(
                                                      color: colorScheme.primary
                                                          .withOpacity(0.7),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                context.push(
                                                    AppRoutes.meetingPath(
                                                        'demo-meeting'));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                    0xFF1B3B2B), // Dark green
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text(
                                                'View',
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ]
                        : [
                            // PAST MEETINGS
                            Text(
                              'PEOPLE YOU\'VE MET',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.5),
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildPastMeetingRow(
                              context: context,
                              name: 'Sarah Jenkins',
                              dateLocation: 'MET 12 AUG • BREW LAB',
                              stars: 5,
                              imageUrl:
                                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop',
                            ),
                            _buildDivider(colorScheme.primary),
                            _buildPastMeetingRow(
                              context: context,
                              name: 'Marcus Chen',
                              dateLocation: 'MET 05 AUG • ORIGIN COFFEE',
                              stars: 4,
                              imageUrl:
                                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150&auto=format&fit=crop',
                              hasBackground: true,
                            ),
                            _buildDivider(colorScheme.primary),
                            _buildPastMeetingRow(
                              context: context,
                              name: 'Elena Rodriguez',
                              dateLocation: 'MET 28 JUL • THE ROASTERY',
                              stars: 2,
                              imageUrl:
                                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
                            ),
                            _buildDivider(colorScheme.primary),
                            _buildPastMeetingRow(
                              context: context,
                              name: 'Anonymous User',
                              dateLocation: 'MET 15 JUL • ESPRESSO RO...',
                              stars: 0,
                              imageUrl:
                                  'https://images.unsplash.com/photo-1599566150163-29194dcaad36?q=80&w=150&auto=format&fit=crop', // generic
                              isFaded: true,
                            ),
                            const SizedBox(
                                height: 24), // padding for bottom nav
                          ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EBE6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Icon(Icons.event_outlined,
                color: colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'STATUS • EMPTY • AWAITING INPUT',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.4),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No coffee planned yet',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pick a time and we'll find someone.",
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 64),
        ],
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
            style: textTheme.bodySmall?.copyWith(
              color: isSelected ? primaryColor : primaryColor.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 2,
              width: label.length * 7.0,
              color: primaryColor,
            )
          else
            const SizedBox(height: 2),
        ],
      ),
    );
  }

  Widget _buildPastMeetingRow({
    required BuildContext context,
    required String name,
    required String dateLocation,
    required int stars,
    required String imageUrl,
    bool hasBackground = false,
    bool isFaded = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Opacity(
        opacity: isFaded ? 0.3 : 1.0,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  isFaded ? Colors.grey.withOpacity(0.2) : Colors.transparent,
              backgroundImage: isFaded ? null : NetworkImage(imageUrl),
              child: isFaded
                  ? Icon(Icons.person,
                      color: colorScheme.primary.withOpacity(0.2))
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLocation,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.5),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: hasBackground
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : EdgeInsets.zero,
              decoration: hasBackground
                  ? BoxDecoration(
                      color: const Color(0xFFE0A008).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: isFaded
                        ? Colors.grey.withOpacity(0.5)
                        : const Color(0xFFE0A008),
                    size: 14,
                  );
                }),
              ),
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
