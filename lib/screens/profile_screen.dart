import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/profile_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/auth_controller.dart';
import 'package:poppylo/state/profile_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _primary = Color(0xFF1D3D33);
  static const _bg = Color(0xFFF3F1EB);

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
            "You'll need to verify your phone number again next time."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Await so the auth guard sees the signed-out state before we
              // navigate — otherwise it can still see isSignedIn: true and
              // bounce this go(welcome) straight back to /home.
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(meProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: me.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _primary),
          ),
          error: (_, __) =>
              _ErrorState(onRetry: () => ref.invalidate(meProvider)),
          data: (data) => _Content(
            me: data,
            onLogout: () => _confirmLogout(context, ref),
            onDeleteAccount: () async {
              HapticFeedback.heavyImpact();
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) context.go(AppRoutes.welcome);
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: ProfileScreen._primary, size: 40),
          const SizedBox(height: 12),
          const Text("Couldn't load your profile",
              style: TextStyle(color: ProfileScreen._primary)),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.me,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final UserMe me;
  final VoidCallback onLogout;
  final Future<void> Function() onDeleteAccount;

  static const _primary = ProfileScreen._primary;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = me.profile;
    final prefs = me.preferences;
    final purposeLabel = purposeLabelFromApi(me.purpose);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: _primary),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoutes.editPreferencesPath);
            },
          ),
        ),
        const SizedBox(height: 16),

        // --- Header: avatar + name/job ---
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _primary.withOpacity(0.2)),
              ),
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _primary.withOpacity(0.08),
                backgroundImage:
                    (profile?.photoUrl != null && profile!.photoUrl!.isNotEmpty)
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                child: (profile?.photoUrl == null || profile!.photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: _primary, size: 34)
                    : null,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile == null
                        ? 'Your profile'
                        : '${profile.firstName}, ${profile.age}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if ((profile?.job ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile!.job!,
                      style: textTheme.bodyMedium
                          ?.copyWith(color: _primary.withOpacity(0.8)),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'COFFEE MEET MEMBER',
                    style: textTheme.labelSmall?.copyWith(
                      color: _primary.withOpacity(0.5),
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

        if ((profile?.bio ?? '').isNotEmpty) ...[
          Text(
            profile!.bio!,
            style: textTheme.bodyMedium
                ?.copyWith(color: _primary.withOpacity(0.8), height: 1.5),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.editProfilePath);
          },
          child: Text(
            'Edit profile',
            style: textTheme.bodyMedium
                ?.copyWith(color: _primary, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 32),

        // --- Stats (static placeholders — no backend yet) ---
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8DF),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Expanded(child: _stat('12', 'COFFEE MEETS', textTheme)),
              _vDivider(),
              Expanded(child: _stat('5', 'CONNECTIONS', textTheme)),
              _vDivider(),
              Expanded(child: _stat('4.9', 'AVG RATING', textTheme)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- Interests ---
        if (me.interests.isNotEmpty) ...[
          _sectionHeader('INTERESTS', textTheme, icon: Icons.edit, onTap: () {
            HapticFeedback.lightImpact();
            context.push(AppRoutes.editProfilePath);
          }),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: [
              for (final i in me.interests) _interestChip(i.label, textTheme),
            ],
          ),
          const SizedBox(height: 32),
        ],

        // --- Looking for ---
        if (purposeLabel.isNotEmpty) ...[
          _sectionHeader('LOOKING FOR', textTheme),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.local_cafe_outlined,
                    color: Colors.white.withOpacity(0.9), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purposeLabel,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (prefs != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Within ${prefs.maxDistanceKm} km • Ages ${prefs.minAge}–${prefs.maxAge}',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.editPreferencesPath),
                  child: const Icon(Icons.chevron_right,
                      color: Colors.white, size: 24),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],

        // --- Settings (static) ---
        _sectionHeader('SETTINGS', textTheme),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              _settingsRow(Icons.tune, 'Preferences', textTheme,
                  onTap: () => context.push(AppRoutes.editPreferencesPath)),
              _divider(),
              _settingsRow(Icons.notifications_none, 'Notifications', textTheme,
                  hasDot: true),
              _divider(),
              _settingsRow(Icons.shield_outlined, 'Safety centre', textTheme),
              _divider(),
              _settingsRow(Icons.help_outline, 'Help and support', textTheme),
              _divider(),
              _settingsRow(Icons.info_outline, 'About Coffee Meet', textTheme),
              _divider(),
              _settingsRow(Icons.delete_outline, 'Delete Account', textTheme,
                  color: Colors.redAccent, onTap: onDeleteAccount),
            ],
          ),
        ),
        const SizedBox(height: 48),

        Center(
          child: TextButton(
            onPressed: onLogout,
            child: Text(
              'Log out',
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFFC04F43),
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
              color: _primary.withOpacity(0.4),
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _stat(String number, String label, TextTheme textTheme) {
    return Column(
      children: [
        Text(number,
            style: textTheme.headlineSmall
                ?.copyWith(color: _primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: _primary.withOpacity(0.6),
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _vDivider() =>
      Container(width: 1, height: 40, color: _primary.withOpacity(0.1));

  Widget _sectionHeader(String title, TextTheme textTheme,
      {IconData? icon, VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: textTheme.labelSmall?.copyWith(
            color: _primary.withOpacity(0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
        if (icon != null)
          GestureDetector(
            onTap: onTap,
            child: Icon(icon, size: 16, color: _primary.withOpacity(0.7)),
          ),
      ],
    );
  }

  Widget _interestChip(String label, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primary.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: textTheme.bodySmall
            ?.copyWith(color: _primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _settingsRow(IconData icon, String label, TextTheme textTheme,
      {bool hasDot = false, VoidCallback? onTap, Color? color}) {
    final c = color ?? _primary;
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: c.withOpacity(0.7), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium
                    ?.copyWith(color: c, fontWeight: FontWeight.w500),
              ),
            ),
            if (hasDot)
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0A008),
                  shape: BoxShape.circle,
                ),
              ),
            Icon(Icons.chevron_right, color: c.withOpacity(0.3), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.only(left: 58, right: 20),
        child: Divider(
          height: 1,
          thickness: 1,
          color: _primary.withOpacity(0.05),
        ),
      );
}
