import 'package:flutter/widgets.dart';

import '../data/progress.dart';

/// Measures time spent on a learning screen and adds it to today's study
/// time when the screen closes. Pauses while the app is in the background.
mixin StudyTimer<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  final Stopwatch _studyWatch = Stopwatch();
  LearningProgress? _studyProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _studyWatch.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _studyProgress = ProgressScope.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _studyWatch.start();
    } else {
      _studyWatch.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _studyWatch.stop();
    _studyProgress?.addStudyTime(_studyWatch.elapsed);
    super.dispose();
  }
}
