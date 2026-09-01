import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart';

class MeetingConfirmedScreen extends ConsumerWidget {
  final String meetingId;
  const MeetingConfirmedScreen({super.key, required this.meetingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final meetingAsync = ref.watch(meetingDetailsProvider(meetingId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1E201F),
        body: SafeArea(
          child: meetingAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (e, _) =>
                _errorBody(context, textTheme, cafeErrorMessage(e)),
            data: (meeting) =>
                _body(context, ref, meeting, textTheme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _errorBody(BuildContext context, TextTheme textTheme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Back home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    MeetingDetails meeting,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final photo = meeting.partner.profileImage;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Ticket card
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9F8F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        child: (photo != null && photo.isNotEmpty)
                            ? Image.network(photo,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover)
                            : Container(
                                height: 180,
                                color: const Color(0xFFE2E8DF),
                                child: const Icon(Icons.person,
                                    size: 64, color: Color(0xFF2B4739)),
                              ),
                      ),
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
                        _detailRow(context, 'PARTNER',
                            meeting.partner.name.toUpperCase()),
                        const SizedBox(height: 16),
                        _detailRow(
                            context, 'TIME', formatMeetingTimeRange(meeting)),
                        const SizedBox(height: 16),
                        _detailRow(context, 'DURATION',
                            '${meeting.durationMinutes} MIN'),
                        const SizedBox(height: 16),
                        _detailRow(context, 'LOCATION',
                            meeting.cafe.name.toUpperCase()),
                        if (meeting.cafe.address.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _detailRow(context, 'ADDRESS',
                              meeting.cafe.address.toUpperCase()),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E201F),
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
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton.icon(
                      onPressed: () => HapticFeedback.lightImpact(),
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text('Get directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B4739),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _outlineButton(
              'Add to calendar',
              onPressed: () => HapticFeedback.lightImpact(),
            ),
            const SizedBox(height: 12),
            _outlineButton(
              'View meeting details',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.meetingPath(meetingId));
              },
            ),
            const SizedBox(height: 12),
            _outlineButton(
              'Message ${meeting.partner.name}',
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.chatByMatchPath(meeting.matchId));
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.home);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Cancel Meeting'),
            ),
            const SizedBox(height: 40),
            _safetyTip(context, textTheme),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(String label, {required VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onPressed == null ? Colors.white38 : Colors.white,
        ),
      ),
    );
  }

  Widget _safetyTip(BuildContext context, TextTheme textTheme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, color: Colors.white54, size: 16),
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
          "Meet in a public place and tell a friend where you're going.",
          style:
              textTheme.bodySmall?.copyWith(color: Colors.white54, height: 1.4),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.primary.withOpacity(0.5),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
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
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 8.0;
    const dashSpace = 6.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, size.height / 2),
          Offset(startX + dashWidth, size.height / 2), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
