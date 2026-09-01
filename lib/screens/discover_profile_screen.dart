import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/models/profile_models.dart'
    show purposeLabelFromApi, kConversationStyleLabelToApi;
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/discover_controller.dart';

const _green = Color(0xFF1B3B2B);
const _bg = Color(0xFFF3F1EB);

/// The full public profile behind "View Profile" in Discover
/// (`GET /discover/:userId`). Public fields only — consistent with the
/// existing Profile UI.
class DiscoverProfileScreen extends ConsumerWidget {
  const DiscoverProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final profile = ref.watch(discoverProfileProvider(userId));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _green),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Profile',
          style: textTheme.titleMedium
              ?.copyWith(color: _green, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: profile.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: _green)),
          error: (e, _) => _Error(
            message: discoverErrorMessage(e),
            onRetry: () => ref.invalidate(discoverProfileProvider(userId)),
          ),
          data: (p) => _Body(profile: p),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.profile});

  final DiscoverUserProfile profile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage =
        profile.profileImage != null && profile.profileImage!.isNotEmpty;
    final nameLine =
        profile.age != null ? '${profile.name}, ${profile.age}' : profile.name;
    final styleLabels = profile.conversationStyles
        .map((s) => _conversationStyleLabel(s))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: _green.withOpacity(0.08),
                  backgroundImage:
                      hasImage ? NetworkImage(profile.profileImage!) : null,
                  child: hasImage
                      ? null
                      : const Icon(Icons.person, color: _green, size: 42),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                nameLine,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (profile.profession != null &&
                  profile.profession!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  profile.profession!,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: _green.withOpacity(0.7)),
                ),
              ],
              if (profile.distanceText.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place_outlined,
                        size: 15, color: _green.withOpacity(0.5)),
                    const SizedBox(width: 4),
                    Text(
                      profile.distanceText,
                      style: textTheme.labelMedium
                          ?.copyWith(color: _green.withOpacity(0.6)),
                    ),
                  ],
                ),
              ],
              if (profile.bio != null && profile.bio!.isNotEmpty)
                _section(
                  context,
                  'About',
                  Text(
                    profile.bio!,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: _green, height: 1.5),
                  ),
                ),
              if (profile.interests.isNotEmpty)
                _section(
                  context,
                  'Interests',
                  _chips(context, profile.interests),
                ),
              if (styleLabels.isNotEmpty || profile.purpose != null)
                _section(
                  context,
                  'Coffee preferences',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (profile.purpose != null)
                        _kv(context, 'Here for',
                            purposeLabelFromApi(profile.purpose)),
                      if (styleLabels.isNotEmpty)
                        _kv(context, 'Conversation', styleLabels.join(', ')),
                    ],
                  ),
                ),
              if (profile.availability.isNotEmpty)
                _section(
                  context,
                  'Availability',
                  _chips(
                    context,
                    profile.availability.map(prettyAvailability).toList(),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                // Existing Coffee Request flow — no second request system.
                context.push(AppRoutes.create);
              },
              icon: const Text('☕', style: TextStyle(fontSize: 16)),
              label: const Text('Invite for Coffee'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(27),
                ),
                textStyle:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: _green.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final textTheme = Theme.of(context).textTheme;
    if (v.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: textTheme.bodyMedium?.copyWith(color: _green),
          children: [
            TextSpan(
              text: '$k  ',
              style: TextStyle(color: _green.withOpacity(0.5)),
            ),
            TextSpan(
              text: v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chips(BuildContext context, List<String> items) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              item,
              style: textTheme.labelMedium?.copyWith(
                color: _green.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  static String _conversationStyleLabel(String apiValue) {
    for (final e in kConversationStyleLabelToApi.entries) {
      if (e.value == apiValue) return e.key;
    }
    return apiValue.isEmpty
        ? apiValue
        : '${apiValue[0].toUpperCase()}${apiValue.substring(1)}';
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium
                  ?.copyWith(color: _green.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}
