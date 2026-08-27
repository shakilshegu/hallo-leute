import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/screens/chat_screen.dart';

class MutualConnectionScreen extends StatelessWidget {
  const MutualConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F1EB), // Warm beige
      body: Container(
        // Neon border effect
        decoration: BoxDecoration(
          border: Border.all(
            width: 4.0,
            color: Colors.transparent, // Handled by gradient wrapper or we can use a custom painter/gradient border.
          ),
        ),
        // A simple way to get gradient border is to wrap in a Container with padding
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFF4169E1)], // Purple to Royal Blue
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          padding: const EdgeInsets.all(4.0), // Border width
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F1EB),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    
                    Text(
                      'You both enjoyed meeting.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Looks like you made a connection.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Overlapping Avatars
                    SizedBox(
                      height: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            left: MediaQuery.of(context).size.width / 2 - 80,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
                              ),
                              child: const CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=150&auto=format&fit=crop'), // User avatar mock
                              ),
                            ),
                          ),
                          Positioned(
                            right: MediaQuery.of(context).size.width / 2 - 80,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFF3F1EB), width: 4),
                              ),
                              child: const CircleAvatar(
                                radius: 48,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'), // Sarah avatar mock
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    Text(
                      'MATCH SECURED • 08:42AM',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary.withOpacity(0.5),
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const ChatScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
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
                          'Continue chat',
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'View profile',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
