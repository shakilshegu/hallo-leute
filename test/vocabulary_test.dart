import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/vocabulary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Vocabulary vocab;
  setUpAll(() async => vocab = await Vocabulary.load());

  test('bundled word list is large and complete', () {
    expect(vocab.words.length, greaterThan(2500));
    for (final w in vocab.words) {
      expect(w.word, isNotEmpty);
      expect(w.meaning, isNotEmpty, reason: w.word);
      if (w.pos == 'noun') {
        expect(['der', 'die', 'das'], contains(w.article), reason: w.word);
      }
    }
    final withExamples = vocab.words.where((w) => w.hasExample).length;
    expect(withExamples / vocab.words.length, greaterThan(0.95));
  });

  test('hand-picked essentials come first', () {
    expect(vocab.words.first.rank, 0);
    expect(vocab.words.any((w) => w.word == 'Krankenversicherung'), isTrue);
  });

  test('every topic has words and credits are present', () {
    for (final t in Topic.values) {
      expect(vocab.countFor(t), greaterThan(0), reason: t.name);
    }
    expect(vocab.sources, hasLength(3));
  });

  test('no word appears twice with the same spelling and class', () {
    final keys = vocab.words.map((w) => '${w.word}|${w.pos}').toList();
    expect(keys.toSet().length, keys.length);
  });
}
