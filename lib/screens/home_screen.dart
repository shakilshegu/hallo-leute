import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/searching_screen.dart';
import 'package:poppylo/widgets/app_bottom_nav.dart';
import 'package:poppylo/screens/waiting_screen.dart';
import 'package:poppylo/widgets/status_sheets.dart';
import 'package:poppylo/screens/match_expired_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  
  // Animation variables
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimation3;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation1 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic)),
    );
    
    _slideAnimation2 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)),
    );
    
    _slideAnimation3 = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic)),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _showCreateMeetSheet() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF3F1EB),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const CreateCoffeeMeetSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              
              // Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation1,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()}, Aisha',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Ready for a good conversation?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.bug_report, color: Colors.grey),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => ListView(
                              children: [
                                ListTile(
                                  title: const Text('Show No Match Sheet'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const NoMatchSheet(),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Show Match Declined Sheet'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const MatchDeclinedSheet(),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Show Network Error Sheet'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => const NetworkErrorSheet(),
                                    );
                                  },
                                ),
                                ListTile(
                                  title: const Text('Show Match Expired Screen'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const MatchExpiredScreen()),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Main Action Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONNECTION AWAITS',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary.withOpacity(0.7),
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Find\nsomeone for\ncoffee',
                          style: textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Choose a time and we'll find someone who's a great fit for a meaningful chat.",
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimary.withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Custom animated button
                        _BouncingButton(
                          onPressed: _showCreateMeetSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6B100),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              'Find my match',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Upcoming Coffee
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UPCOMING COFFEE',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary.withOpacity(0.5),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      CustomPaint(
                        painter: _DashedBorderPainter(color: colorScheme.primary.withOpacity(0.3)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Text(
                                'No coffee planned yet',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.primary.withOpacity(0.7),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _showCreateMeetSheet,
                                child: Text(
                                  'Create a Coffee Meet',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

// Custom bouncing button for a more tactile feel
class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _BouncingButton({required this.child, required this.onPressed});

  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// Custom painter for dashed borders
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(16),
      ));

    final dashWidth = 8.0;
    final dashSpace = 6.0;
    
    // Quick approximation of dashed path
    double distance = 0.0;
    final metrics = path.computeMetrics().toList()[0];
    final length = metrics.length;
    
    final dashedPath = Path();
    while (distance < length) {
      dashedPath.addPath(
        metrics.extractPath(distance, distance + dashWidth),
        Offset.zero,
      );
      distance += dashWidth + dashSpace;
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------
// Bottom Sheet for Creating a Coffee Meet
// ---------------------------------------------------------
class CreateCoffeeMeetSheet extends StatefulWidget {
  const CreateCoffeeMeetSheet({super.key});

  @override
  State<CreateCoffeeMeetSheet> createState() => _CreateCoffeeMeetSheetState();
}

class _CreateCoffeeMeetSheetState extends State<CreateCoffeeMeetSheet> {
  String _when = 'Today';
  String _time = '5:00 PM';
  String _duration = '45 min';
  String _distance = '10 km';
  
  final Set<String> _why = {'Make friends'};
  final Set<String> _conversation = {'Deep'};

  void _toggleSet(Set<String> set, String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  Widget _buildSectionTitle(String title, TextTheme textTheme, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: textTheme.labelSmall?.copyWith(
          color: color.withOpacity(0.5),
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPillToggle({
    required String value,
    required String selectedValue,
    required Function(String) onSelect,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    IconData? icon,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSelect(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip({
    required String value,
    required Set<String> selectedSet,
    required Function(String) onToggle,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final isSelected = selectedSet.contains(value);
    return GestureDetector(
      onTap: () => onToggle(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Find someone for coffee',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WHEN
                    _buildSectionTitle('WHEN', textTheme, colorScheme.primary),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPillToggle(
                            value: 'Today',
                            selectedValue: _when,
                            onSelect: (v) => setState(() => _when = v),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(width: 8),
                          _buildPillToggle(
                            value: 'Tomorrow',
                            selectedValue: _when,
                            onSelect: (v) => setState(() => _when = v),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                          const SizedBox(width: 8),
                          _buildPillToggle(
                            value: 'Pick Date',
                            selectedValue: _when,
                            onSelect: (v) => setState(() => _when = v),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // TIME
                    _buildSectionTitle('TIME', textTheme, colorScheme.primary),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['3:00 PM', '4:00 PM', '5:00 PM', '6:00 PM', '7:00 PM']
                            .map((t) => Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: _buildPillToggle(
                                    value: t,
                                    selectedValue: _time,
                                    onSelect: (v) => setState(() => _time = v),
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // HOW LONG
                    _buildSectionTitle('HOW LONG', textTheme, colorScheme.primary),
                    Row(
                      children: ['30 min', '45 min', '60 min']
                          .map((t) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: t != '60 min' ? 8.0 : 0),
                                  child: _buildPillToggle(
                                    value: t,
                                    selectedValue: _duration,
                                    onSelect: (v) => setState(() => _duration = v),
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // HOW FAR
                    _buildSectionTitle('HOW FAR', textTheme, colorScheme.primary),
                    Row(
                      children: ['2 km', '5 km', '10 km']
                          .map((d) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: d != '10 km' ? 8.0 : 0),
                                  child: _buildPillToggle(
                                    value: d,
                                    selectedValue: _distance,
                                    onSelect: (v) => setState(() => _distance = v),
                                    colorScheme: colorScheme,
                                    textTheme: textTheme,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // WHY
                    _buildSectionTitle('WHY', textTheme, colorScheme.primary),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 12.0,
                      children: [
                        'Make friends', 'Networking', 'Shared interests', 'Dating', 'Conversation'
                      ].map((w) => _buildMultiSelectChip(
                            value: w,
                            selectedSet: _why,
                            onToggle: (v) => _toggleSet(_why, v),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          )).toList(),
                    ),
                    const SizedBox(height: 32),
                    
                    // CONVERSATION
                    _buildSectionTitle('CONVERSATION', textTheme, colorScheme.primary),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 12.0,
                      children: [
                        'Casual', 'Deep', 'Career', 'Hobbies', 'Anything'
                      ].map((c) => _buildMultiSelectChip(
                            value: c,
                            selectedSet: _conversation,
                            onToggle: (v) => _toggleSet(_conversation, v),
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          )).toList(),
                    ),
                    
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            
            // Bottom Action
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchingScreen(),
                      ),
                    );
                  },
                  icon: Icon(Icons.search, color: colorScheme.onPrimary),
                  label: Text(
                    'Find my match',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
