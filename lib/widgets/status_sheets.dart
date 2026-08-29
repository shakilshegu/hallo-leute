import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NoMatchSheet extends StatelessWidget {
  const NoMatchSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseStatusSheet(
      icon: Icons.coffee_outlined,
      title: 'No match this time',
      body: 'Nobody free at 5 PM within 5 km today.',
      extraWidget: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE6EBE6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '5:00 PM • 5 KM • TODAY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Text(
              'CHANGE TIME',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1B3B2B),
              side: const BorderSide(color: Color(0xFF1B3B2B), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
            ),
            child: Text(
              'EXPAND DISTANCE',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF1B3B2B),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class MatchDeclinedSheet extends StatelessWidget {
  const MatchDeclinedSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseStatusSheet(
      icon: Icons.coffee_outlined,
      breadcrumbs: 'STATUS • PASSED • MATCH',
      title: 'Sarah passed this time',
      body: 'It happens. Someone else is probably free.',
      actions: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'FIND ANOTHER MATCH',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NetworkErrorSheet extends StatelessWidget {
  const NetworkErrorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return _BaseStatusSheet(
      icon: Icons.wifi_off_outlined,
      breadcrumbs: 'ERROR • NETWORK • 503',
      title: 'Can\'t connect',
      body: 'Check your connection and try again.',
      actions: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            label: Text(
              'Try again',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B3B2B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Text(
            'CANCEL',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _BaseStatusSheet extends StatelessWidget {
  final IconData icon;
  final String? breadcrumbs;
  final String title;
  final String body;
  final Widget? extraWidget;
  final List<Widget> actions;

  const _BaseStatusSheet({
    required this.icon,
    this.breadcrumbs,
    required this.title,
    required this.body,
    this.extraWidget,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 32,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EBE6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 32),
          ),
          const SizedBox(height: 24),

          if (breadcrumbs != null) ...[
            Text(
              breadcrumbs!,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary.withOpacity(0.4),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
          ],

          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            body,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),

          if (extraWidget != null) extraWidget!,

          ...actions,
        ],
      ),
    );
  }
}
