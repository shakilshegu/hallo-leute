import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:poppylo/models/discover_models.dart';

const _green = Color(0xFF1B3B2B);

/// A single person in the Discover feed. Calm, coffee-focused — not a swipe
/// card. Follows the existing Coffee Meet card style (white, rounded, soft
/// shadow).
class DiscoverPersonCard extends StatelessWidget {
  const DiscoverPersonCard({
    super.key,
    required this.user,
    required this.onViewProfile,
    required this.onInvite,
  });

  final DiscoverUser user;
  final VoidCallback onViewProfile;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasImage = user.profileImage != null && user.profileImage!.isNotEmpty;
    final nameLine = user.age != null ? '${user.name}, ${user.age}' : user.name;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _green.withOpacity(0.08),
                backgroundImage:
                    hasImage ? NetworkImage(user.profileImage!) : null,
                child: hasImage
                    ? null
                    : const Icon(Icons.person, color: _green, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameLine,
                      style: textTheme.titleMedium?.copyWith(
                        color: _green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.profession != null &&
                        user.profession!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.profession!,
                        style: textTheme.bodySmall?.copyWith(
                          color: _green.withOpacity(0.7),
                        ),
                      ),
                    ],
                    if (user.distanceText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 13, color: _green.withOpacity(0.45)),
                          const SizedBox(width: 3),
                          Text(
                            user.distanceText,
                            style: textTheme.labelSmall?.copyWith(
                              color: _green.withOpacity(0.5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (user.compatibilityScore > 0)
                _ScoreBadge(user.compatibilityScore),
            ],
          ),
          if (user.interests.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              user.interests.take(4).join('  •  '),
              style: textTheme.labelMedium?.copyWith(
                color: _green.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              user.bio!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: _green.withOpacity(0.75),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    onViewProfile();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: BorderSide(color: _green.withOpacity(0.2)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onInvite();
                  },
                  icon: const Text('☕', style: TextStyle(fontSize: 14)),
                  label: const Text('Invite'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge(this.score);
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _green.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$score% match',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
      ),
    );
  }
}
