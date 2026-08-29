import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poppylo/router/routes.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: colorScheme.primary,
                  onPressed: () {},
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
                  backgroundImage: NetworkImage(
                      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=100&auto=format&fit=crop'), // User avatar mock
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        children: [
          // Hero Image
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=600&auto=format&fit=crop', // Same as avatar
              height: 360,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // Name and Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Alex Chen ',
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '28',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'PRODUCT DESIGNER • SAN FRANCISCO',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Bio
          Text(
            'Obsessed with typography, specialty light roasts, and building tools that connect people. Always down to chat about design systems or your latest side project over a pour-over.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary.withOpacity(0.8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // Interests
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag('POUR OVER', true, colorScheme, textTheme),
              _buildTag('DESIGN', false, colorScheme, textTheme),
              _buildTag('STARTUPS', false, colorScheme, textTheme),
              _buildTag('ESPRESSO', false, colorScheme, textTheme),
            ],
          ),
          const SizedBox(height: 32),

          // Stats Row
          Row(
            children: [
              Expanded(
                  child: _buildStatCard(
                      '12', 'COFFEE MEETS', colorScheme, textTheme)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatCard(
                      '5', 'CONNECTIONS', colorScheme, textTheme)),
            ],
          ),
          const SizedBox(height: 32),

          // Settings Menu
          _buildMenuRow(context, Icons.edit_outlined, 'Edit profile',
              onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.editProfilePath);
          }),
          _buildMenuRow(context, Icons.tune, 'Preferences', onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.editPreferencesPath);
          }),
          _buildMenuRow(context, Icons.shield_outlined, 'Safety'),
          _buildMenuRow(context, Icons.notifications_none, 'Notifications'),
          _buildMenuRow(context, Icons.help_outline, 'Help'),
          const SizedBox(height: 24), // padding for bottom nav
        ],
      ),
    );
  }

  Widget _buildTag(String label, bool isSelected, ColorScheme colorScheme,
      TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1B3B2B) : const Color(0xFFE6EBE6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color:
              isSelected ? Colors.white : colorScheme.primary.withOpacity(0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildStatCard(String number, String label, ColorScheme colorScheme,
      TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.primary.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap ??
          () {
            HapticFeedback.selectionClick();
          },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary.withOpacity(0.7), size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right,
                color: colorScheme.primary.withOpacity(0.3), size: 24),
          ],
        ),
      ),
    );
  }
}
