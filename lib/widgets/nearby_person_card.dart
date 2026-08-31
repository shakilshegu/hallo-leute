import 'package:flutter/material.dart';

import 'package:poppylo/models/discover_models.dart';
import 'package:poppylo/widgets/coffee_meet_card.dart' show formatDistance;

const _green = Color(0xFF1B3B2B);

class NearbyPersonCard extends StatelessWidget {
  const NearbyPersonCard({
    super.key,
    required this.person,
    required this.onViewProfile,
  });

  final NearbyPerson person;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 158,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: _green.withOpacity(0.08),
            backgroundImage: NetworkImage(person.avatarUrl),
          ),
          const SizedBox(height: 10),
          Text(
            person.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: _green,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${formatDistance(person.distanceKm)} away',
            style: textTheme.labelSmall?.copyWith(
              color: _green.withOpacity(0.5),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final tag in person.interestTags.take(2))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: textTheme.labelSmall?.copyWith(
                      color: _green.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: OutlinedButton(
              onPressed: onViewProfile,
              style: OutlinedButton.styleFrom(
                foregroundColor: _green,
                side: BorderSide(color: _green.withOpacity(0.2)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: Text(
                'View Profile',
                style: textTheme.labelSmall?.copyWith(
                  color: _green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
