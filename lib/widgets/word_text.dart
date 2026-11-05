import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Makes [word] bold (in its article colour) inside [sentence].
TextSpan highlightWord(String sentence, String word, Article? article) {
  final i = sentence.toLowerCase().indexOf(word.toLowerCase());
  if (i < 0) return TextSpan(text: sentence);
  return TextSpan(
    children: [
      TextSpan(text: sentence.substring(0, i)),
      TextSpan(
        text: sentence.substring(i, i + word.length),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: article?.textColor ?? AppColors.ink,
        ),
      ),
      TextSpan(text: sentence.substring(i + word.length)),
    ],
  );
}
