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
  bool _isEmpty = true; // Set to true to show empty state

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: colorScheme.primary,
                  onPressed: () {
                    // Hidden dev toggle for testing empty state
                    setState(() => _isEmpty = !_isEmpty);
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Coffee Meet',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'), // User avatar mock
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: Text(
              'Meetings',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Tab row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTab('Upcoming', 0, colorScheme, textTheme),
                const SizedBox(width: 24),
                _buildTab('Past', 1, colorScheme, textTheme),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Divider below tabs
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 24),
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
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            'CONFIRMED',
                                            style: textTheme.labelSmall?.copyWith(
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SAT 5:00 PM • BREW LAB • 45 MIN',
                                          style: textTheme.labelSmall?.copyWith(
                                            color: colorScheme.primary.withOpacity(0.5),
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 20,
                                              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=150&auto=format&fit=crop'), // Sarah
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Sarah',
                                                    style: textTheme.titleMedium?.copyWith(
                                                      color: colorScheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Coffee enthusiast & designer',
                                                    style: textTheme.bodySmall?.copyWith(
                                                      color: colorScheme.primary.withOpacity(0.7),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton(
                                              onPressed: () {
                                                HapticFeedback.lightImpact();
                                                context.push(AppRoutes
                                                    .meetingPath('demo-meeting'));
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1B3B2B), // Dark green
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                              ),
                                              child: Text(
                                                'View',
                                                style: textTheme.labelSmall?.copyWith(
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
                              'Past',
                              style: textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            _buildPastMeetingRow(
                              context: context,
                              name: 'James',
                              status: 'COMPLETED',
                              date: 'OCT 12 • 7 PM',
                              location: 'GLASSHAUS',
                              stars: 5,
                              imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop',
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            _buildPastMeetingRow(
                              context: context,
                              name: 'Elena',
                              status: 'COMPLETED',
                              date: 'SEP 28 • 10 AM',
                              location: 'ORIGIN ROASTERS',
                              stars: 4,
                              imageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150&auto=format&fit=crop',
                            ),
                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            _buildPastMeetingRow(
                              context: context,
                              name: 'Marcus',
                              status: 'COMPLETED',
                              date: 'SEP 15 • 2 PM',
                              location: 'BLUE BOTTLE',
                              stars: 5,
                              imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
                            ),
                            const SizedBox(height: 24), // padding for bottom nav
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
            child: Icon(Icons.event_outlined, color: colorScheme.primary, size: 32),
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

  Widget _buildTab(String label, int index, ColorScheme colorScheme, TextTheme textTheme) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedTabIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1B3B2B) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.5),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPastMeetingRow({
    required BuildContext context,
    required String name,
    required String status,
    required String date,
    required String location,
    required int stars,
    required String imageUrl,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(imageUrl),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EBE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$date\n$location',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.5),
                  height: 1.3,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < stars ? Icons.star : Icons.star_border,
              color: const Color(0xFFE6A316),
              size: 16,
            );
          }),
        ),
      ],
    );
  }
}
