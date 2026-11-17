import 'package:flutter/material.dart';

/// Hallo Leute palette, sampled from the frying-pan logo.
///
/// Navy + cream carry the brand; mustard is the single warm accent
/// ("Nur positiv") and should be used sparingly for highlights.
abstract final class AppColors {
  // Navy (logo background) and its tints for surfaces.
  static const navy950 = Color(0xFF0B1830);
  static const navy = Color(0xFF13294B);
  static const navy800 = Color(0xFF1B355D);
  static const navy700 = Color(0xFF25436F);
  static const navyLine = Color(0xFF34558A);

  // Cream (logo lettering) and a muted variant for secondary text.
  static const cream = Color(0xFFF5ECD7);
  static const creamMuted = Color(0xFFBFC3C9);

  // Accent.
  static const mustard = Color(0xFFF2B544);
  static const mustardDeep = Color(0xFFD99A2B);

  // Feedback (used sparingly: wrong answers, destructive actions).
  static const coral = Color(0xFFE88A7A);
}
