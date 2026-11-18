// Renders the Poppylo icon PNGs from the same drawing code as the in-app
// logo (PoppyloMark), so they always match.
//
//   flutter test tool/icon/generate_icon_test.dart
//   dart run flutter_launcher_icons && dart run flutter_native_splash:create
//
// Outputs:
//   assets/brand/app_icon.png             1024², navy background (iOS, web, legacy Android)
//   assets/brand/app_icon_foreground.png  1024², transparent, inside the adaptive safe zone
//   assets/brand/splash_logo.png          1024², transparent, for the launch screen
//   android/.../drawable-*/ic_notification.png  white silhouette for the status bar
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poppylo/shared/widgets/poppylo_logo.dart';
import 'package:poppylo/theme/app_colors.dart';

Future<void> _render(
  String path,
  int px, {
  Color? background,
  required double scale,
  bool silhouette = false,
}) async {
  final size = px.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.saveLayer(Offset.zero & Size(size, size), Paint());
  if (background != null) {
    canvas.drawRect(Offset.zero & Size(size, size), Paint()..color = background);
  }
  final art = size * scale;
  canvas.translate((size - art) / 2, (size - art) / 2);
  if (silhouette) {
    // White bubble with the flower cut out (Android status-bar style).
    PoppyloMark.paint(
      canvas,
      art,
      bubbleColor: Colors.white,
      knockout: true,
    );
  } else {
    PoppyloMark.paint(canvas, art);
  }
  canvas.restore();
  final image = await recorder.endRecording().toImage(px, px);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('generate app icons', (tester) async {
    await tester.runAsync(() async {
      await _render(
        'assets/brand/app_icon.png',
        1024,
        background: AppColors.navy,
        scale: 0.74,
      );
      // Adaptive icons are masked to ~66% of the canvas: keep the mark inside.
      await _render('assets/brand/app_icon_foreground.png', 1024, scale: 0.56);
      await _render('assets/brand/splash_logo.png', 1024, scale: 0.8);

      const densities = {
        'mdpi': 24,
        'hdpi': 36,
        'xhdpi': 48,
        'xxhdpi': 72,
        'xxxhdpi': 96,
      };
      for (final e in densities.entries) {
        await _render(
          'android/app/src/main/res/drawable-${e.key}/ic_notification.png',
          e.value,
          scale: 0.92,
          silhouette: true,
        );
      }
    });
  });
}
