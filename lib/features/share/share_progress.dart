import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/progress.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../shared/widgets/poppylo_logo.dart';

/// Shows a preview of the progress card, then shares it as an image
/// (WhatsApp, Instagram, anywhere) with a short message.
Future<void> showShareProgress(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.navy950,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _ShareSheet(),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet();

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share(int learned) async {
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/poppylo_progress.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
      final text = learned == 0
          ? "I'm learning German with Poppylo! 🇩🇪"
          : "I've learned $learned German words with Poppylo! 🇩🇪 "
                'Learn with me, a few minutes a day.';
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      debugPrint('Share failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not share right now.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ProgressScope.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cream.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: RepaintBoundary(
                key: _cardKey,
                child: ShareCard(
                  learned: p.totalLearned,
                  streak: p.streak,
                  mastered: p.totalMastered,
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _busy ? 'Preparing…' : 'Share my progress',
              onPressed: _busy ? null : () => _share(p.totalLearned),
            ),
          ],
        ),
      ),
    );
  }
}

/// The image people see on WhatsApp.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.learned,
    required this.streak,
    required this.mastered,
  });

  final int learned;
  final int streak;
  final int mastered;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const RadialGradient(
            center: Alignment(0, -0.5),
            radius: 1.2,
            colors: [AppColors.navy800, AppColors.navy, AppColors.navy950],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: FittedBox(
                child: PoppyloLogo(
                  size: 110,
                  entrance: const AlwaysStoppedAnimation(1),
                  ambient: const AlwaysStoppedAnimation(0),
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                '$learned',
                style: AppText.display(64, color: AppColors.mustard, height: 1),
              ),
            ),
            Text(
              learned == 1 ? 'German word learned' : 'German words learned',
              style: AppText.body(
                15,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Pill(
                  icon: Icons.local_fire_department_rounded,
                  text: '$streak-day streak',
                ),
                const SizedBox(width: 8),
                _Pill(icon: Icons.star_rounded, text: '$mastered mastered'),
              ],
            ),
            const Spacer(),
            Text(
              'Learning German with Poppylo',
              style: AppText.body(12, color: AppColors.creamMuted),
            ),
            Text(
              'poppylo.com',
              style: AppText.body(
                11.5,
                weight: FontWeight.w800,
                color: AppColors.mustard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.cream.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.mustard),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  12,
                  weight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
