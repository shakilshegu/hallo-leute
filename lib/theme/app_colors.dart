import 'package:flutter/material.dart';

import '../data/models.dart';

export '../data/models.dart' show Article;

/// Poppylo global colour palette.
///
/// Bright colours are for large shapes (buttons, cards, rings, badges).
/// Use the `*Text` twins whenever the colour is used for small text,
/// so it stays readable (contrast ≈ 4.5:1 on [cream]).
class AppColors {
  AppColors._();

  // Brand
  static const poppy = Color(0xFFFF5E5B); // primary – brand moments
  static const poppyText = Color(0xFFD63A3A);
  static const sunrise = Color(0xFFFF9A4D); // streaks, rewards
  static const sunriseText = Color(0xFFB85A14);
  static const lavender = Color(0xFF8B6CFF); // quizzes, badges
  static const lavenderText = Color(0xFF6A4BE0);

  // Neutrals
  static const ink = Color(0xFF15151C); // headings, main buttons
  static const muted = Color(0xFF6B6B78); // secondary text
  static const cream = Color(0xFFFFF8F3); // app background
  static const surface = Color(0xFFFFFFFF); // cards
  static const outline = Color(0xFFEDE6E1);

  // Feedback (always pair with an icon, never colour alone)
  static const success = Color(0xFF22A06B);
  static const error = Color(0xFFB42318);
  static const warning = Color(0xFFF5A524);

  // German articles – the same colour everywhere in the app
  static const der = Color(0xFF4F8BFF);
  static const derText = Color(0xFF2F6FE0);
  static const die = Color(0xFFFF5E7E);
  static const dieText = Color(0xFFD6336C);
  static const das = Color(0xFF22A06B);
  static const dasText = Color(0xFF17834F);

  /// Signature gradient (Poppy → Sunrise) for accents and highlights.
  static const bloomGradient = LinearGradient(colors: [poppy, sunrise]);
}

/// Article colours – the same everywhere in the app.
extension ArticleColors on Article {
  Color get color => switch (this) {
    Article.der => AppColors.der,
    Article.die => AppColors.die,
    Article.das => AppColors.das,
  };

  Color get textColor => switch (this) {
    Article.der => AppColors.derText,
    Article.die => AppColors.dieText,
    Article.das => AppColors.dasText,
  };
}
