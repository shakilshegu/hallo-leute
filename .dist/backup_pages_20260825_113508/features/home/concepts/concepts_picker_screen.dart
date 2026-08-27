import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dev-only screen for comparing the three homepage concepts side by side.
/// Not part of the real onboarding → login → home flow.
class ConceptsPickerScreen extends StatelessWidget {
  const ConceptsPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Homepage Concepts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Pick a concept to preview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _ConceptTile(
            title: 'Playful Gamified',
            subtitle: 'Live at /home · XP, level, streak, badges, big Continue Learning CTA',
            color: const Color(0xFFFF6F00),
            onTap: () => context.push('/home'),
          ),
          const SizedBox(height: 12),
          _ConceptTile(
            title: 'Premium Modern',
            subtitle: 'Clean, minimal, elegant cards, subtle gamification',
            color: const Color(0xFF4C4FE0),
            onTap: () => context.push('/concepts/premium'),
          ),
          const SizedBox(height: 12),
          _ConceptTile(
            title: 'Interactive Adventure',
            subtitle: 'Winding learning path, milestones, unlockable lessons',
            color: const Color(0xFF6D28D9),
            onTap: () => context.push('/concepts/adventure'),
          ),
        ],
      ),
    );
  }
}

class _ConceptTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ConceptTile({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}
