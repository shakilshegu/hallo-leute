import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:poppylo/router/routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final primaryColor = const Color(0xFF1D3D33); // Dark green
    final bgColor = const Color(0xFFF3F1EB); // Base app background

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // Top Bar with Settings
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.settings_outlined, color: primaryColor),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoutes.editPreferencesPath);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Profile Info (Avatar + Details)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200&auto=format&fit=crop'), // Aisha
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0A008), // Yellow badge
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aisha, 28',
                        style: textTheme.headlineSmall?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Product designer',
                        style: textTheme.bodyMedium?.copyWith(
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'KOCHI • JOINED MAR 2024',
                        style: textTheme.labelSmall?.copyWith(
                          color: primaryColor.withOpacity(0.5),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bio
            Text(
              'Obsessed with typography, specialty light roasts, and building tools that connect people. Always down to chat about design systems.',
              style: textTheme.bodyMedium?.copyWith(
                color: primaryColor.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.editProfilePath);
              },
              child: Text(
                'Edit profile',
                style: textTheme.bodyMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Stats Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8DF), // Light greyish green
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _buildStatColumn(
                          '12', 'COFFEE MEETS', primaryColor, textTheme)),
                  Container(
                      width: 1, height: 40, color: primaryColor.withOpacity(0.1)),
                  Expanded(
                      child: _buildStatColumn(
                          '5', 'CONNECTIONS', primaryColor, textTheme)),
                  Container(
                      width: 1, height: 40, color: primaryColor.withOpacity(0.1)),
                  Expanded(
                      child: _buildStatColumn(
                          '4.9', 'AVG RATING', primaryColor, textTheme)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Interests Section
            _buildSectionHeader('INTERESTS',
                icon: Icons.edit, primaryColor: primaryColor, textTheme: textTheme),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: [
                _buildInterestChip('Travel', primaryColor, textTheme),
                _buildInterestChip('Design', primaryColor, textTheme),
                _buildInterestChip('Startups', primaryColor, textTheme),
                _buildInterestChip('Coffee', primaryColor, textTheme),
                _buildInterestChip('Books', primaryColor, textTheme),
              ],
            ),
            const SizedBox(height: 32),

            // Looking For Section
            _buildSectionHeader('LOOKING FOR',
                primaryColor: primaryColor, textTheme: textTheme),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      color: Colors.white.withOpacity(0.9), size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shared interests',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Casual conversation • Within 5 km • Ages 24 to 34',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right, color: Colors.white, size: 24),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // People You've Met
            _buildSectionHeader('PEOPLE YOU\'VE MET',
                actionText: 'See all',
                primaryColor: primaryColor,
                textTheme: textTheme),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMetPerson('Marcus', 'AUG 2024',
                    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=150&auto=format&fit=crop',
                    primaryColor, textTheme),
                _buildMetPerson('Elena', 'JUL 2024',
                    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=150&auto=format&fit=crop',
                    primaryColor, textTheme),
                _buildMetPerson('David', 'JUN 2024',
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=150&auto=format&fit=crop',
                    primaryColor, textTheme),
              ],
            ),
            const SizedBox(height: 32),

            // Settings Section
            _buildSectionHeader('SETTINGS',
                primaryColor: primaryColor, textTheme: textTheme),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  _buildSettingsRow(Icons.tune, 'Preferences', primaryColor, textTheme),
                  _buildDivider(primaryColor),
                  _buildSettingsRow(Icons.notifications_none, 'Notifications',
                      primaryColor, textTheme,
                      hasDot: true),
                  _buildDivider(primaryColor),
                  _buildSettingsRow(Icons.shield_outlined, 'Safety centre',
                      primaryColor, textTheme),
                  _buildDivider(primaryColor),
                  _buildSettingsRow(Icons.help_outline, 'Help and support',
                      primaryColor, textTheme),
                  _buildDivider(primaryColor),
                  _buildSettingsRow(Icons.info_outline, 'About Coffee Meet',
                      primaryColor, textTheme),
                ],
              ),
            ),
            const SizedBox(height: 48),

            // Footer
            Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Log out',
                  style: textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFC04F43), // Red/Orange
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'COFFEE MEET • VERSION 1.0.2',
                style: textTheme.labelSmall?.copyWith(
                  color: primaryColor.withOpacity(0.4),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 48), // Padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String number, String label, Color primaryColor, TextTheme textTheme) {
    return Column(
      children: [
        Text(
          number,
          style: textTheme.headlineSmall?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: primaryColor.withOpacity(0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title,
      {IconData? icon,
      String? actionText,
      required Color primaryColor,
      required TextTheme textTheme}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.labelSmall?.copyWith(
            color: primaryColor.withOpacity(0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        if (icon != null)
          Icon(icon, size: 16, color: primaryColor.withOpacity(0.7)),
        if (actionText != null)
          Text(
          actionText,
          style: textTheme.labelSmall?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestChip(String label, Color primaryColor, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.1),
        ),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetPerson(String name, String date, String imageUrl,
      Color primaryColor, TextTheme textTheme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundImage: NetworkImage(imageUrl),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: textTheme.bodyMedium?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          date,
          style: textTheme.labelSmall?.copyWith(
            color: primaryColor.withOpacity(0.5),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(
      IconData icon, String label, Color primaryColor, TextTheme textTheme,
      {bool hasDot = false}) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: primaryColor.withOpacity(0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasDot)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0A008), // Yellow dot
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right,
                color: primaryColor.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 58, right: 20), // Align with text
      child: Divider(
        height: 1,
        thickness: 1,
        color: primaryColor.withOpacity(0.05),
      ),
    );
  }
}
