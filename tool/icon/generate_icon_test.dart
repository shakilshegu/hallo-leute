// Renders the app icon PNGs from code so they stay crisp and on-brand.
//
//   flutter test tool/icon/generate_icon_test.dart
//   dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// Outputs (1024×1024):
//   assets/brand/app_icon.png             navy background (iOS, web, legacy Android)
//   assets/brand/app_icon_foreground.png  transparent, inside the adaptive safe zone
//   assets/brand/splash_logo.png          transparent, for the launch screen
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/theme/app_colors.dart';
import 'package:hallo_leute/theme/app_text.dart';

const _size = 1024.0;

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  await (FontLoader(
    family,
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

/// The pan with a diagonal handle and the HALLO / LEUTE wordmark.
class _IconPainter extends CustomPainter {
  _IconPainter({required this.background, required this.scale});

  final bool background;

  /// Fraction of the canvas the artwork occupies (adaptive safe zone < 1).
  final double scale;

  static const _ink = AppColors.cream;
  static const _bg = AppColors.navy;

  @override
  void paint(Canvas canvas, Size size) {
    if (background) {
      canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
    }

    // Artwork box, centred.
    final art = size.width * scale;
    canvas.save();
    canvas.translate((size.width - art) / 2, (size.height - art) / 2);

    final d = art * 0.68; // pan diameter
    final r = d / 2;
    // Pan sits up-left so the diagonal handle balances the composition.
    final c = Offset(art * 0.43, art * 0.43);
    final stroke = d * 0.05;

    // Handle, pointing to the bottom-right.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(math.pi / 4);
    final handle = Path()
      ..moveTo(r * 0.85, -0.17 * d)
      ..cubicTo(
        r + 0.04 * d,
        -0.15 * d,
        r + 0.07 * d,
        -0.065 * d,
        r + 0.17 * d,
        -0.06 * d,
      )
      ..lineTo(r + 0.42 * d, -0.075 * d)
      ..arcToPoint(
        Offset(r + 0.42 * d, 0.075 * d),
        radius: Radius.circular(0.075 * d),
      )
      ..lineTo(r + 0.17 * d, 0.06 * d)
      ..cubicTo(
        r + 0.07 * d,
        0.065 * d,
        r + 0.04 * d,
        0.15 * d,
        r * 0.85,
        0.17 * d,
      )
      ..close();
    canvas.drawPath(handle, Paint()..color = _ink);
    canvas.drawRRect(
      RRect.fromLTRBR(
        r + 0.30 * d,
        -0.026 * d,
        r + 0.44 * d,
        0.026 * d,
        Radius.circular(0.026 * d),
      ),
      Paint()..color = _bg,
    );
    canvas.restore();

    // Pan interior + ring.
    canvas.drawCircle(c, r - stroke / 2, Paint()..color = _bg);
    canvas.drawCircle(
      c,
      r - stroke / 2,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Wordmark: two lines of bubbly, slightly tilted letters.
    final style = AppText.display(
      d * 0.215,
      weight: FontWeight.w700,
      color: _ink,
      height: 1,
    );
    const lines = [
      (
        'HALLO',
        [-0.06, 0.03, -0.03, 0.05, -0.04],
        [0.0, -0.02, 0.01, -0.03, 0.01],
      ),
      (
        'LEUTE',
        [0.04, -0.035, 0.05, -0.02, 0.035],
        [0.02, 0.0, -0.02, 0.01, -0.01],
      ),
    ];
    final lineHeight = d * 0.22;
    for (var li = 0; li < lines.length; li++) {
      final (word, tilts, offsets) = lines[li];
      final painters = [
        for (final ch in word.split(''))
          TextPainter(
            text: TextSpan(text: ch, style: style),
            textDirection: TextDirection.ltr,
          )..layout(),
      ];
      final width = painters.fold<double>(0, (s, p) => s + p.width);
      var x = c.dx - width / 2;
      final y = c.dy - d * 0.07 + (li - 0.5) * lineHeight;
      for (var i = 0; i < painters.length; i++) {
        final p = painters[i];
        canvas.save();
        canvas.translate(x + p.width / 2, y + offsets[i] * d);
        canvas.rotate(tilts[i]);
        p.paint(canvas, Offset(-p.width / 2, -p.height / 2));
        canvas.restore();
        x += p.width;
      }
    }

    // Smile.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: d * 0.29),
      math.pi / 2 - 0.42,
      0.84,
      false,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.028
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _render(
  String path, {
  required bool background,
  required double scale,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _IconPainter(
    background: background,
    scale: scale,
  ).paint(canvas, const Size(_size, _size));
  final image = await recorder.endRecording().toImage(
    _size.toInt(),
    _size.toInt(),
  );
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('generate app icons', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Fredoka', 'assets/fonts/Fredoka.ttf');
      await _render('assets/brand/app_icon.png', background: true, scale: 0.86);
      // Adaptive icons: Android masks to ~66% of the canvas, keep art inside.
      await _render(
        'assets/brand/app_icon_foreground.png',
        background: false,
        scale: 0.6,
      );
      await _render(
        'assets/brand/splash_logo.png',
        background: false,
        scale: 0.9,
      );
    });
  });
}
