import 'package:flutter_test/flutter_test.dart';
import 'package:hallo_leute/data/local_store.dart';
import 'package:hallo_leute/data/progress.dart';
import 'package:hallo_leute/data/vocabulary.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(Vocabulary.load);
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('PrefsStore reads back what it writes', () async {
    final store = PrefsStore.create();
    expect(await store.read('k'), isNull);
    await store.write('k', 'v');
    expect(await store.read('k'), 'v');
    await store.remove('k');
    expect(await store.read('k'), isNull);
  });

  test('progress saved through PrefsStore loads in a new session', () async {
    final first = await LearningProgress.load(PrefsStore.create());
    first.recordAnswer(vocabulary[3], knewIt: true);
    await pumpEventQueue();

    final second = await LearningProgress.load(PrefsStore.create());
    expect(second.isLearned(vocabulary[3]), isTrue);
  });
}
