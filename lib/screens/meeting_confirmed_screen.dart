import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

class MeetingConfirmedScreen extends StatelessWidget {
  final String meetingId;
  const MeetingConfirmedScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF1E201F), // Dark charcoal background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header text on dark background
                Text(
                  'Your Coffee Meet is confirmed.',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Get ready for a great conversation.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Main Ticket Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F5), // Light cream
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      // Top Image with Checkmark
                      Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                            child: Image.network(
                              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=600&auto=format&fit=crop', // Sarah's larger image
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Gradient fade to blend image into background
                          Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFF9F8F5).withOpacity(0.0),
                                  const Color(0xFFF9F8F5),
                                ],
                              ),
                            ),
                          ),
                          // Checkmark badge
                          Transform.translate(
                            offset: const Offset(0, 20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9F8F5),
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: colorScheme.primary, width: 2),
                                ),
                                child: Icon(Icons.check,
                                    color: colorScheme.primary, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Details section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            Text(
                              'MEETING DETAILS',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary.withOpacity(0.5),
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildDetailRow(context, 'PARTNER', 'SARAH, 27'),
                            const SizedBox(height: 16),
                            _buildDetailRow(
                                context, 'TIME', 'SATURDAY 5:00 PM – 5:45 PM'),
                            const SizedBox(height: 16),
                            _buildDetailRow(context, 'LOCATION', 'BREW LAB'),
                            const SizedBox(height: 16),
                            _buildDetailRow(context, 'DISTANCE', '1.2 KM'),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Dashed Divider
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E201F), // Match dark background
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomPaint(
                              painter: DashedLinePainter(
                                  color: colorScheme.primary.withOpacity(0.2)),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1E201F),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Map & Directions
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://images.unsplash.com/photo-1524661135-423995f22d0b?q=80&w=600&auto=format&fit=crop', // Placeholder map
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                              },
                              icon: const Icon(Icons.directions, size: 18),
                              label: const Text('Get directions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2B4739),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Actions
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3B2B),
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Add to calendar',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.meetingPath(meetingId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('View meeting details',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push(AppRoutes.chatPath(meetingId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Message Sarah',
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.home);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Cancel Meeting'),
                ),
                const SizedBox(height: 48),

                // Safety Tip
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shield_outlined,
                            color: Colors.white54, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'SAFETY TIP',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.white54,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Meet in a public place and tell a friend where you're\ngoing.",
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    var max = size.width;
    var dashWidth = 8.0;
    var dashSpace = 6.0;
    double startX = 0;

    while (startX < max) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
