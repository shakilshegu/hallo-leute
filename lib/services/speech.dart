import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../theme/app_colors.dart';

/// German pronunciation with the phone's built-in text-to-speech voice.
/// Works offline once the German voice is installed (it is on most phones).
class Speech {
  Speech._();

  static final Speech instance = Speech._();

  FlutterTts? _tts;
  bool _ready = false;
  bool _unavailable = false;

  /// Text currently being spoken (drives the speaker icon animation).
  final ValueNotifier<String?> speaking = ValueNotifier(null);

  Future<bool> _ensure() async {
    if (_ready) return true;
    if (_unavailable) return false;
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('de-DE');
      await tts.setSpeechRate(0.42); // a little slower than normal: learners
      await tts.setPitch(1.0);
      tts.setCompletionHandler(() => speaking.value = null);
      tts.setCancelHandler(() => speaking.value = null);
      tts.setErrorHandler((_) => speaking.value = null);
      _ready = true;
      return true;
    } on Object catch (e) {
      // No TTS engine (tests, rare devices): buttons simply do nothing.
      debugPrint('Speech unavailable: $e');
      _unavailable = true;
      return false;
    }
  }

  /// Says [text] in German. Tapping again while it speaks restarts it.
  Future<void> say(String text) async {
    if (text.trim().isEmpty || !await _ensure()) return;
    try {
      await _tts!.stop();
      speaking.value = text;
      await _tts!.speak(text);
      // Safety net in case the engine never reports completion.
      Timer(Duration(milliseconds: 900 + text.length * 90), () {
        if (speaking.value == text) speaking.value = null;
      });
    } on Object catch (e) {
      debugPrint('Speech failed: $e');
      speaking.value = null;
    }
  }

  Future<void> stop() async {
    speaking.value = null;
    if (_ready) await _tts?.stop();
  }
}

/// Round speaker button. Pulses while its text is being spoken.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.text,
    this.size = 40,
    this.onLight = false,
  });

  final String text;
  final double size;

  /// Styling for cream (light) surfaces.
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: Speech.instance.speaking,
      builder: (context, current, _) {
        final active = current == text;
        final fg = onLight ? AppColors.navy : AppColors.mustard;
        final bg = onLight
            ? AppColors.navy.withValues(alpha: active ? 0.16 : 0.08)
            : AppColors.cream.withValues(alpha: active ? 0.16 : 0.07);
        return Semantics(
          button: true,
          label: 'Listen: $text',
          excludeSemantics: true,
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Speech.instance.say(text),
              child: SizedBox.square(
                dimension: size,
                child: AnimatedScale(
                  scale: active ? 1.15 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    active ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                    size: size * 0.5,
                    color: fg,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
