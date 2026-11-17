import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_text.dart';

/// Faint everyday German words drifting slowly in the background.
/// Purely decorative: ignored by hit-testing and screen readers.
class FloatingWords extends StatelessWidget {
  const FloatingWords({super.key, required this.ambient, required this.reveal});

  final Animation<double> ambient;
  final Animation<double> reveal;

  static const _words = [
    ('Guten Tag', Alignment(-0.82, -0.80), 20.0, 0.0),
    ('Danke', Alignment(0.80, -0.90), 18.0, 0.21),
    ('Bitte', Alignment(0.92, -0.30), 19.0, 0.47),
    ("Wie geht's?", Alignment(-0.95, -0.22), 17.0, 0.63),
    ('der · die · das', Alignment(0.85, 0.58), 16.0, 0.35),
    ('Tschüss', Alignment(-0.82, 0.64), 18.0, 0.82),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([ambient, reveal]),
          builder: (context, _) {
            final a = ambient.value;
            return Opacity(
              opacity: reveal.value,
              child: Stack(
                children: [
                  for (final (word, align, size, phase) in _words)
                    Align(
                      alignment: align,
                      child: Transform.translate(
                        offset: Offset(
                          4 * math.cos(2 * math.pi * (a + phase)),
                          10 * math.sin(2 * math.pi * (a + phase)),
                        ),
                        child: Text(
                          word,
                          style: AppText.display(
                            size,
                            weight: FontWeight.w500,
                            color: AppColors.cream.withValues(alpha: 0.075),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
