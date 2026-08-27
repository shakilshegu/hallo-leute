import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:poppylo/screens/choose_cafe_screen.dart';

class MatchStatusScreen extends StatefulWidget {
  const MatchStatusScreen({super.key});

  @override
  State<MatchStatusScreen> createState() => _MatchStatusScreenState();
}

class _MatchStatusScreenState extends State<MatchStatusScreen> with TickerProviderStateMixin {
  bool _isMatched = false;
  
  // Transition animations
  late AnimationController _transitionController;
  late Animation<double> _slideUserAvatar;
  late Animation<double> _slideSarahAvatar;
  late Animation<double> _heartScale;

  // Radar sweep animation for waiting state
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    
    // Setup transition animation
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideUserAvatar = Tween<double>(begin: -100, end: -40).animate(
      CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    
    _slideSarahAvatar = Tween<double>(begin: 0, end: 40).animate(
      CurvedAnimation(parent: _transitionController, curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack)),
    );
    
    _heartScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _transitionController, curve: const Interval(0.5, 1.0, curve: Curves.elasticOut)),
    );

    // Setup radar sweep animation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    // Simulate match happening after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _isMatched = true;
        });
        _radarController.stop();
        _transitionController.forward();
      }
    });
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Center alignment
            children: [
              const Spacer(flex: 2),
              
              // Top Tag / Title
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                crossFadeState: _isMatched ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E7C9), // Light beige background
                          border: Border.all(
                            color: const Color(0xFFE5C88B), // More prominent yellow/beige border
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'WAITING',
                          style: textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFDCAE5A), // Soft yellow/orange text
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                secondChild: Column(
                  children: [
                    Text(
                      "It's a match",
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You both want to meet. Now\nchoose where.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.7),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              
              // Avatars Animation
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_transitionController, _radarController]),
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Static Background Circle
                        if (!_isMatched)
                          Container(
                            width: 200,
                            height: 200,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFEBE6D8),
                            ),
                          ),
                          
                        // Radar Sweep Animation
                        if (!_isMatched)
                          RotationTransition(
                            turns: _radarController,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: SweepGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.transparent,
                                    const Color(0xFFDCAE5A).withOpacity(0.0), // Faded yellow
                                    const Color(0xFFDCAE5A).withOpacity(0.4), // Bright yellow sector edge
                                  ],
                                  stops: const [0.0, 0.7, 0.95, 1.0],
                                  transform: const GradientRotation(math.pi / 2),
                                ),
                              ),
                            ),
                          ),

                        // User Avatar (slides in from left)
                        if (_isMatched)
                          Transform.translate(
                            offset: Offset(_slideUserAvatar.value, 0),
                            child: Opacity(
                              opacity: _transitionController.value.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
                                ),
                                child: const CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200&auto=format&fit=crop',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                        // Sarah Avatar (centered, then slides right)
                        Transform.translate(
                          offset: Offset(_slideSarahAvatar.value, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isMatched ? const Color(0xFFF3F1EB) : Colors.white, 
                                width: _isMatched ? 4 : 3, // White border in waiting state
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 48,
                              backgroundImage: NetworkImage(
                                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop',
                              ),
                            ),
                          ),
                        ),
                        
                        // Heart Badge
                        if (_isMatched)
                          Transform.scale(
                            scale: _heartScale.value,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6B100), // Yellow
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
                              ),
                              child: Icon(
                                Icons.favorite,
                                color: colorScheme.primary, // Dark green heart
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Waiting Text
              if (!_isMatched)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center, // Center align
                  children: [
                    Text(
                      'Waiting for Sarah',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We'll let you know as soon as she accepts.",
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.6),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
              if (!_isMatched) const SizedBox(height: 48),
              
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                crossFadeState: _isMatched ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'SATURDAY 5:00 PM',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.6),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center, // Center align time
                  ),
                ),
                secondChild: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'SATURDAY · 5:00 PM · 45 MIN',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary.withOpacity(0.6),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center, // Center for match state
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
              
              // Bottom Actions
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 400),
                crossFadeState: _isMatched ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel request',
                    style: textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB54C4C), // Slightly softer red based on screenshot
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                secondChild: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: Duration.zero,
                              pageBuilder: (context, animation, secondaryAnimation) => const ChooseCafeScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B3B2B), // Dark green
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Choose a café',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Text(
                          'Message later',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
