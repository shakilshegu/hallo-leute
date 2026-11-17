import 'package:flutter/material.dart';

/// Text style helpers.
///
/// Both bundled fonts are variable fonts, so every style sets the `wght`
/// axis explicitly in addition to [FontWeight].
abstract final class AppText {
  /// Rounded display face, echoes the bubbly logo lettering.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style('Fredoka', size, weight, color, height, letterSpacing);

  /// Friendly, highly legible body face.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => _style('Nunito', size, weight, color, height, letterSpacing);

  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}
