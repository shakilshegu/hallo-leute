import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/widgets/app_bottom_nav.dart';
import 'package:poppylo/screens/feedback_screen.dart'; // We will wire this up for testing

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _selectedTabIndex = 0; // 0 for ACTIVE, 1 for PAST
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
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'), // Example user avatar
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Text(
              'Matches',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Custom Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = 0);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 0 ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'ACTIVE',
                            style: textTheme.labelSmall?.copyWith(
                              color: _selectedTabIndex == 0 ? Colors.white : colorScheme.primary.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTabIndex = 1);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _selectedTabIndex == 1 ? colorScheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            'PAST',
                            style: textTheme.labelSmall?.copyWith(
                              color: _selectedTabIndex == 1 ? Colors.white : colorScheme.primary.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Matches List or Empty State
          Expanded(
            child: _isEmpty
                ? _buildEmptyState(context)
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    children: _selectedTabIndex == 0
                        ? [
                            // ACTIVE MATCHES
                            _buildMatchCard(
                              context: context,
                              name: 'Sarah, 28',
                              jobTitle: 'UX Designer',
                              imageUrl: 'https://images.unsplash.com/photo-1551818255-e6e10975bc17?q=80&w=600&auto=format&fit=crop',
                              matchInfo: '02 MATCH · SAT 5 PM',
                              status: 'CONFIRMED',
                              tags: ['POUR OVER', 'QUIET'],
                            ),
                            const SizedBox(height: 16),
                            _buildMatchCard(
                              context: context,
                              name: 'Michael, 31',
                              jobTitle: 'Software Engineer',
                              imageUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=600&auto=format&fit=crop',
                              matchInfo: '01 MATCH · SUN 10 AM',
                              status: 'PENDING',
                              tags: ['ESPRESSO', 'STARTUPS'],
                            ),
                            const SizedBox(height: 24),
                          ]
                        : [
                            // PAST MATCHES
                            _buildMatchCard(
                              context: context,
                              name: 'Jessica, 26',
                              jobTitle: 'Product Manager',
                              imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop',
                              matchInfo: 'OCT 12 · BREW LAB',
                              status: 'COMPLETED',
                              tags: ['LATTE', 'DESIGN'],
                            ),
                            const SizedBox(height: 16),
                            _buildMatchCard(
                              context: context,
                              name: 'David, 29',
                              jobTitle: 'Photographer',
                              imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=600&auto=format&fit=crop',
                              matchInfo: 'SEP 28 · ORIGIN',
                              status: 'COMPLETED',
                              tags: ['COLD BREW', 'ART'],
                            ),
                            const SizedBox(height: 24),
                          ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1), // Matches tab is index 1
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
            child: Icon(Icons.coffee_outlined, color: colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'STATUS • WAIT 202',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.4),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No matches yet',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your matches will show up here once you find someone with shared tastes.',
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

  Widget _buildMatchCard({
    required BuildContext context,
    required String name,
    required String jobTitle,
    required String imageUrl,
    required String matchInfo,
    required String status,
    required List<String> tags,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F0),
        borderRadius: BorderRadius.circular(24),
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
                  imageUrl,
                  height: 200,
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
                    status,
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
                  matchInfo,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary.withOpacity(0.5),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          jobTitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.forum_outlined),
                      color: colorScheme.primary,
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFE6EBE6),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tags
                Wrap(
                  spacing: 8,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EBE6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  )).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Directions Button (Wired to Feedback for testing!)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // We route to Feedback Screen here just for easy testing
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const FeedbackScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
                    icon: const Icon(Icons.directions_walk, size: 20, color: Colors.white),
                    label: Text(
                      'DIRECTIONS',
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
