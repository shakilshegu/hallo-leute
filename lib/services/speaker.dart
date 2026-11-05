import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Speaks German text aloud.
abstract interface class Speaker {
  Future<void> speak(String text);
}

/// Uses the phone's own text-to-speech engine with a German voice.
class TtsSpeaker implements Speaker {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.45); // a little slower for learners
    await _tts.setPitch(1.0);
    _ready = true;
  }

  @override
  Future<void> speak(String text) async {
    try {
      if (!_ready) await _init();
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      // No TTS engine / German voice – fail silently, never crash a lesson.
      debugPrint('TTS unavailable: $e');
    }
  }
}

final speakerProvider = Provider<Speaker>((ref) => TtsSpeaker());
