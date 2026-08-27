import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/widgets/cancel_meeting_sheet.dart';
import 'package:poppylo/screens/report_user_screen.dart';

class SafetyCenterSheet extends StatelessWidget {
  const SafetyCenterSheet({super.key});

  void _showCancelMeetingSheet(BuildContext context) {
    HapticFeedback.mediumImpact();
    // Close the current sheet first
    Navigator.pop(context);
    
    // Show the cancel sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CancelMeetingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: colorScheme.primary.withOpacity(0.5),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Safety Center',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Balance for back button
            ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'Meet safely',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'A few things that keep this good for everyone.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Tip Cards
          _buildTipCard(
            context,
            icon: Icons.store_outlined,
            title: 'Meet in a public place',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            context,
            icon: Icons.lock_outline,
            title: 'Keep personal details private',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            context,
            icon: Icons.location_on_outlined,
            title: "Tell someone where you're going",
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            context,
            icon: Icons.exit_to_app,
            title: 'You can leave at any time',
          ),
          
          const SizedBox(height: 32),
          Divider(color: Colors.grey.withOpacity(0.2)),
          const SizedBox(height: 24),

          Text(
            'SECONDARY ACTIONS',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          _buildDangerButton(
            context: context,
            icon: Icons.report_problem_outlined,
            label: 'Report user',
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context); // close sheet
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReportUserScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildDangerButton(
            context: context,
            icon: Icons.block,
            label: 'Block user',
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          _buildDangerButton(
            context: context,
            icon: Icons.cancel_outlined,
            label: 'Cancel meeting',
            onPressed: () => _showCancelMeetingSheet(context),
            isLight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, {required IconData icon, required String title}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EBE6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isLight = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFFD32F2F), size: 20),
        label: Text(
          label,
          style: textTheme.titleSmall?.copyWith(
            color: const Color(0xFFD32F2F),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isLight ? const Color(0xFFEBEBEB) : const Color(0xFFFFEBEE),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
