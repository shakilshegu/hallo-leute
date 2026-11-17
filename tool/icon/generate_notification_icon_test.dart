// Renders the white status-bar icon used by reminders:
//   flutter test tool/icon/generate_notification_icon_test.dart
// Android requires a white silhouette on transparent, in each density.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _densities = {
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

void _paintPan(Canvas canvas, double s) {
  final white = Paint()..color = Colors.white;
  final d = s * 0.62;
  final r = d / 2;
  final c = Offset(s * 0.42, s * 0.42);
  // Handle (diagonal), then a ring with a hollow centre and a smile.
  canvas.save();
  canvas.translate(c.dx, c.dy);
  canvas.rotate(math.pi / 4);
  canvas.drawRRect(
    RRect.fromLTRBR(
      r * 0.7,
      -d * 0.09,
      r + d * 0.5,
      d * 0.09,
      Radius.circular(d * 0.09),
    ),
    white,
  );
  canvas.restore();
  canvas.drawCircle(c, r, white);
  canvas.drawCircle(c, r * 0.72, Paint()..blendMode = BlendMode.clear);
  canvas.drawArc(
    Rect.fromCircle(center: c, radius: r * 0.42),
    math.pi / 2 - 0.7,
    1.4,
    false,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round,
  );
}

void main() {
  testWidgets('generate notification icons', (tester) async {
    await tester.runAsync(() async {
      for (final e in _densities.entries) {
        final size = e.value.toDouble();
        final rec = ui.PictureRecorder();
        final canvas = Canvas(rec);
        canvas.saveLayer(Offset.zero & Size(size, size), Paint());
        _paintPan(canvas, size);
        canvas.restore();
        final img = await rec.endRecording().toImage(e.value, e.value);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('android/app/src/main/res/drawable-${e.key}')
          ..createSync(recursive: true);
        File('${dir.path}/ic_notification.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}
