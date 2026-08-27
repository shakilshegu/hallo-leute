import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_svg/flutter_svg.dart';

/// PLAYFUL GAMIFIED home screen — the live "/home" screen.
/// Energetic, colorful, strongly gamified: level + XP, streak, a prominent
/// Continue Learning CTA, and an achievements row sit on top of the
/// existing underwater/character world.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/background.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.4, 0.6, 1.0],
                    colors: [
                      Color(0xFFE0F7FA), // Light sky blue
                      Color(0xFFB2EBF2), // Slightly deeper sky
                      Color(0xFF0277BD), // Water transition
                      Color(0xFF01579B), // Deep ocean blue
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
                const SliverToBoxAdapter(child: _HomeHeader()),
                SliverToBoxAdapter(child: const SizedBox(height: 20)),
                const SliverToBoxAdapter(child: _ContinueLearningCard()),
                SliverToBoxAdapter(child: const SizedBox(height: 12)),
                const SliverToBoxAdapter(child: _HeroCharacters()),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -60), // Pulls the underwater image up to blend over the grass water edge
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/underwater.png'),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        children: const [
                          SizedBox(height: 120), // Compensates for the upward shift
                          _ActivityGrid(),
                          SizedBox(height: 36),
                          _AchievementsRow(),
                          SizedBox(height: 36),
                          _OngoingSessions(),
                          SizedBox(height: 120), // Space for bottom nav
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Custom Bottom Navigation
          const Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _CustomBottomNav(),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.pink[100],
                      child: const Icon(Icons.person, color: Colors.pink),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Guten Morgen,',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          'Priya Mehaboob',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0277BD),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Streak Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      SvgPicture.asset('assets/egg.svg', width: 36, height: 36),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Text(
                            'x3',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0277BD),
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'streak',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0277BD),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Days column
                  Column(
                    children: ['T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                      final isToday = day == 'T'; // Mock logic for 'Today'
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: isToday ? Colors.white : Colors.white.withOpacity(0.5),
                          child: Text(
                            day,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isToday ? const Color(0xFF0277BD) : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _LevelXpBar(),
        ],
      ),
    );
  }
}

/// Compact Level + XP progress bar — keeps gamification visible at all times.
class _LevelXpBar extends StatelessWidget {
  const _LevelXpBar();

  @override
  Widget build(BuildContext context) {
    const currentXp = 180;
    const nextLevelXp = 250;
    const progress = currentXp / nextLevelXp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
              ),
            ),
            child: const Center(
              child: Text(
                '4',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Level 4',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                    Text(
                      '180 / 250 XP',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0277BD)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.6),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
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

/// Big, unmissable "Continue Learning" call to action.
class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6F00).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/crocodile.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.style, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'CONTINUE LEARNING',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Flash Cards · Lesson 6',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pick up right where you left off',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFFFF6F00), size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCharacters extends StatelessWidget {
  const _HeroCharacters();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Grass ground line
          Positioned(
            bottom: 0,
            left: -20,
            right: -20,
            child: Image.asset(
              'assets/grass.png',
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.green[400],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(200, 40),
                    topRight: Radius.elliptical(200, 40),
                  ),
                ),
              ),
            ),
          ),
          // Character Placeholders
          Padding(
            padding: const EdgeInsets.only(bottom: 90), // Push up to grass level
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
              // Monster Character
              Image.asset(
                'assets/monster.png',
                height: 190,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 120,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.green[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(60), bottom: Radius.circular(20)),
                  ),
                  child: const Center(
                    child: Icon(Icons.smart_toy_rounded, size: 60, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8), // Small natural gap
              // Girl Character
              Image.asset(
                'assets/girl.png',
                height: 310,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.brown[300],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(40), bottom: Radius.circular(10)),
                  ),
                  child: const Center(
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

class _ActivityGrid extends StatelessWidget {
  const _ActivityGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildActivityCard('Flash Cards', Icons.style, context, imagePath: 'assets/flashcards.png')),
              const SizedBox(width: 16),
              Expanded(child: _buildActivityCard('Grammatic', Icons.menu_book, context, imagePath: 'assets/grammar.png')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildActivityCard('Vocabulary', Icons.sort_by_alpha, context, imagePath: 'assets/vocabulary.png')),
              const SizedBox(width: 16),
              Expanded(child: _buildActivityCard('Quiz', Icons.quiz, context, imagePath: 'assets/quiz.png')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(String title, IconData icon, BuildContext context, {String? imagePath}) {
    return Container(
      height: 170, // Slightly taller for the pop-out effect
      margin: const EdgeInsets.only(top: 50),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background Label Box (the glassmorphic container)
          Container(
            height: 85,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1F6B92).withOpacity(0.95), // Approximate dark blue
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lorem Ipsum dollor',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Glow and Image / Icon
          if (imagePath != null)
            Positioned(
              bottom: 55, // Moves the image higher up
              left: -40,
              right: -40,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Glow Effect
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 40,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  // Character Image
                  Image.asset(
                    imagePath,
                    height: 170, // Made the image larger so text is visible
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(icon, size: 50, color: Colors.greenAccent),
                  ),
                ],
              ),
            )
          else
            Positioned(
              bottom: 60,
              child: Icon(icon, size: 50, color: Colors.greenAccent),
            ),
        ],
      ),
    );
  }
}

/// Horizontal row of unlocked / locked achievement badges.
class _AchievementsRow extends StatelessWidget {
  const _AchievementsRow();

  static const _badges = [
    _Badge('7-Day Streak', Icons.local_fire_department, true),
    _Badge('First Quiz', Icons.military_tech, true),
    _Badge('Vocab Master', Icons.workspace_premium, true),
    _Badge('Grammar Pro', Icons.emoji_events, false),
    _Badge('50 Lessons', Icons.star, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Achievements',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            itemCount: _badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final badge = _badges[index];
              return _BadgeChip(badge: badge);
            },
          ),
        ),
      ],
    );
  }
}

class _Badge {
  final String label;
  final IconData icon;
  final bool unlocked;
  const _Badge(this.label, this.icon, this.unlocked);
}

class _BadgeChip extends StatelessWidget {
  final _Badge badge;
  const _BadgeChip({required this.badge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: badge.unlocked
                  ? const LinearGradient(colors: [Color(0xFFFFD54F), Color(0xFFFFA000)])
                  : null,
              color: badge.unlocked ? null : Colors.white.withOpacity(0.15),
              border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
              boxShadow: badge.unlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFA000).withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              badge.unlocked ? badge.icon : Icons.lock,
              color: badge.unlocked ? Colors.white : Colors.white54,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badge.unlocked ? Colors.white : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}

class _OngoingSessions extends StatelessWidget {
  const _OngoingSessions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'On Going Sessions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildSessionCard('Flash Cards', 0.6, characterImage: 'assets/crocodile.png'),
          const SizedBox(height: 12),
          _buildSessionCard('Grammar', 0.4, characterImage: 'assets/frog.png'),
          const SizedBox(height: 12),
          _buildSessionCard('Vocabulary', 0.8, characterImage: 'assets/crocodile.png'),
          const SizedBox(height: 12),
          _buildSessionCard('Quiz', 0.3, characterImage: 'assets/frog.png'),
        ],
      ),
    );
  }

  Widget _buildSessionCard(String title, double progress, {String? characterImage}) {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Card
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0074B7), // Lighter deep blue
                    Color(0xFF003B73), // Darker deep blue
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),

          // Character Image popping out
          if (characterImage != null)
            Positioned(
              left: -10, // Slight overflow for the pop-out effect
              bottom: 0, // Align to bottom so it doesn't get cut off weirdly at the bottom
              child: Image.asset(
                characterImage,
                height: 105, // Taller than the 80px container so it pops out of the top
                fit: BoxFit.contain,
              ),
            ),

          // Content
          Positioned.fill(
            child: Row(
                children: [
                  SizedBox(width: characterImage != null ? 85 : 16), // Space for character
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          '12 Lessons | Mission Completed',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Custom Progress Bar
                        _buildProgressBar(progress),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right Arrow Button
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shortcut, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: 12,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              // Background track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Filled track gradient
              Container(
                height: 8,
                width: width * progress,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF29B6F6), Color(0xFFFFF176)], // Light blue to yellow
                  ),
                ),
              ),
              // Glowing thumb indicator
              Positioned(
                left: (width * progress) - 4, // Center on the edge of progress
                child: Container(
                  width: 8,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF004D40).withOpacity(0.7), // Teal-ish glass
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, true),
              _buildNavItem(Icons.book_outlined, false),
              _buildNavItem(Icons.storefront_outlined, false),
              _buildNavItem(Icons.lightbulb_outline, false),
              _buildNavItem(Icons.person_outline, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.lightGreen : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.white : Colors.white70,
        size: 24,
      ),
    );
  }
}
