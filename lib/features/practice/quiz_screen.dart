import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../services/speech.dart';
import '../../shared/study_timer.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/fill_or_scroll.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'quiz_engine.dart';

extension PracticeModeText on PracticeMode {
  String get title => switch (this) {
    PracticeMode.article => 'der · die · das',
    PracticeMode.meaning => 'Meaning',
    PracticeMode.listening => 'Listening',
    PracticeMode.spelling => 'Spelling',
    PracticeMode.flashcard => 'Flashcards',
  };

  String get subtitle => switch (this) {
    PracticeMode.article => 'Choose the right article',
    PracticeMode.meaning => 'Pick the English meaning',
    PracticeMode.listening => 'Hear it, find it',
    PracticeMode.spelling => 'Type the German word',
    PracticeMode.flashcard => 'Flip and recall',
  };

  IconData get icon => switch (this) {
    PracticeMode.article => Icons.style_outlined,
    PracticeMode.meaning => Icons.translate_rounded,
    PracticeMode.listening => Icons.headphones_rounded,
    PracticeMode.spelling => Icons.keyboard_alt_outlined,
    PracticeMode.flashcard => Icons.layers_outlined,
  };
}

/// A 10-question practice session in one mode (optionally one topic).
class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.mode,
    required this.questions,
    this.topic,
  });

  final PracticeMode mode;
  final List<Question> questions;
  final Topic? topic;

  static Route<void> route(
    BuildContext context,
    PracticeMode mode, {
    Topic? topic,
  }) {
    final engine = QuizEngine(ProgressScope.of(context));
    final questions = engine.build(mode, topic: topic);
    return MaterialPageRoute<void>(
      builder: (_) =>
          QuizScreen(mode: mode, questions: questions, topic: topic),
    );
  }

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with WidgetsBindingObserver, StudyTimer {
  int _index = 0;
  int _correct = 0;

  /// What the learner chose for the current question (null = unanswered).
  String? _picked;
  bool _wasRight = false;
  final _typed = TextEditingController();
  final _focus = FocusNode();

  Question get _q => widget.questions[_index];
  bool get _done => _index >= widget.questions.length;
  bool get _answered => _picked != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShow());
  }

  @override
  void dispose() {
    _typed.dispose();
    _focus.dispose();
    Speech.instance.stop();
    super.dispose();
  }

  void _onShow() {
    if (!mounted || _done) return;
    if (widget.mode == PracticeMode.listening) {
      Speech.instance.say(_spoken(_q.word));
    }
  }

  static String _spoken(GermanWord w) =>
      [w.article, w.word].where((s) => s.isNotEmpty).join(' ');

  void _answer(String choice) {
    if (_answered) return;
    final right = widget.mode == PracticeMode.spelling
        ? QuizEngine.spellingMatches(choice, _q.answer)
        : choice == _q.answer;
    HapticFeedback.mediumImpact();
    ProgressScope.of(context)
        .recordPractice(_q.word, correct: right, mode: widget.mode);
    setState(() {
      _picked = choice;
      _wasRight = right;
      if (right) _correct++;
    });
    // Hear the right answer: pronunciation sticks better with sound.
    if (widget.mode != PracticeMode.listening) {
      Speech.instance.say(_spoken(_q.word));
    }
  }

  void _next() {
    setState(() {
      _index++;
      _picked = null;
      _wasRight = false;
      _typed.clear();
    });
    if (!_done && widget.mode == PracticeMode.spelling) _focus.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onShow());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return _Shell(child: _Empty(onClose: () => Navigator.of(context).pop()));
    }
    return _Shell(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _done
            ? _QuizSummary(
                key: const ValueKey('summary'),
                mode: widget.mode,
                correct: _correct,
                total: widget.questions.length,
                onAgain: () => Navigator.of(context).pushReplacement(
                  QuizScreen.route(context, widget.mode, topic: widget.topic),
                ),
                onDone: () => Navigator.of(context).pop(),
              )
            : _questionView(),
      ),
    );
  }

  Widget _questionView() {
    final total = widget.questions.length;
    return Column(
      key: ValueKey(_index),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.cream),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: (_index + (_answered ? 1 : 0)) / total),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      color: AppColors.mustard,
                      backgroundColor: AppColors.cream.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '${_index + 1}/$total',
                style: AppText.body(
                  13,
                  weight: FontWeight.w800,
                  color: AppColors.creamMuted,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _prompt,
                  textAlign: TextAlign.center,
                  style: AppText.body(
                    13,
                    weight: FontWeight.w800,
                    color: AppColors.mustard,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                _PromptCard(question: _q, revealed: _answered),
                const SizedBox(height: 22),
                _answers(),
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => SizeTransition(
            sizeFactor: a,
            alignment: Alignment.topCenter,
            child: child,
          ),
          child: _answered
              ? _Feedback(
                  key: const ValueKey('feedback'),
                  right: _wasRight,
                  question: _q,
                  last: _index == total - 1,
                  onContinue: _next,
                )
              : const SizedBox(key: ValueKey('none'), width: double.infinity),
        ),
      ],
    );
  }

  String get _prompt => switch (widget.mode) {
    PracticeMode.article => 'WHICH ARTICLE?',
    PracticeMode.meaning => 'WHAT DOES IT MEAN?',
    PracticeMode.listening => 'LISTEN AND CHOOSE',
    PracticeMode.spelling => 'WRITE IT IN GERMAN',
    PracticeMode.flashcard => '',
  };

  Widget _answers() {
    if (widget.mode == PracticeMode.spelling) {
      return _SpellingInput(
        controller: _typed,
        focus: _focus,
        enabled: !_answered,
        result: _answered ? _wasRight : null,
        onSubmit: () {
          if (_typed.text.trim().isNotEmpty) _answer(_typed.text);
        },
      );
    }
    final row = widget.mode == PracticeMode.article;
    final buttons = [
      for (final o in _q.options)
        _OptionButton(
          label: o,
          big: row,
          state: !_answered
              ? _OptionState.idle
              : o == _q.answer
              ? _OptionState.correct
              : o == _picked
              ? _OptionState.wrong
              : _OptionState.dimmed,
          onTap: () => _answer(o),
        ),
    ];
    if (row) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (final b in buttons) ...[b, const SizedBox(height: 10)],
      ],
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.question, required this.revealed});

  final Question question;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    final w = question.word;
    final spoken = [w.article, w.word].where((s) => s.isNotEmpty).join(' ');
    Widget content;
    switch (question.mode) {
      case PracticeMode.article:
        content = Column(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: revealed ? '${w.article} ' : '___ ',
                    style: AppText.display(34, color: AppColors.mustard),
                  ),
                  TextSpan(
                    text: w.word,
                    style: AppText.display(34, color: AppColors.cream),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              w.meaning,
              textAlign: TextAlign.center,
              style: AppText.body(15, color: AppColors.creamMuted),
            ),
          ],
        );
      case PracticeMode.meaning:
        content = Column(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  if (w.article.isNotEmpty)
                    TextSpan(
                      text: '${w.article} ',
                      style: AppText.display(34, color: AppColors.mustard),
                    ),
                  TextSpan(
                    text: w.word,
                    style: AppText.display(34, color: AppColors.cream),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SpeakButton(text: spoken, size: 44),
          ],
        );
      case PracticeMode.listening:
        content = Column(
          children: [
            SpeakButton(text: spoken, size: 76),
            const SizedBox(height: 12),
            Text(
              revealed ? w.meaning : 'Tap to hear it again',
              textAlign: TextAlign.center,
              style: AppText.body(14.5, color: AppColors.creamMuted),
            ),
          ],
        );
      case PracticeMode.spelling:
        content = Column(
          children: [
            Text(
              w.meaning,
              textAlign: TextAlign.center,
              style: AppText.display(28, color: AppColors.cream, height: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              w.article.isNotEmpty
                  ? '${w.article} …  (${w.word.length} letters)'
                  : '${w.word.length} letters',
              style: AppText.body(
                14,
                weight: FontWeight.w700,
                color: AppColors.creamMuted,
              ),
            ),
          ],
        );
      case PracticeMode.flashcard:
        content = const SizedBox.shrink();
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
      ),
      child: content,
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.state,
    required this.onTap,
    this.big = false,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _OptionState.idle => (
        AppColors.navy800.withValues(alpha: 0.6),
        AppColors.navyLine.withValues(alpha: 0.6),
        AppColors.cream,
      ),
      _OptionState.correct => (
        AppColors.mustard,
        AppColors.mustard,
        AppColors.navy,
      ),
      _OptionState.wrong => (
        AppColors.coral.withValues(alpha: 0.18),
        AppColors.coral,
        AppColors.coral,
      ),
      _OptionState.dimmed => (
        AppColors.navy800.withValues(alpha: 0.3),
        AppColors.navyLine.withValues(alpha: 0.3),
        AppColors.creamMuted.withValues(alpha: 0.6),
      ),
    };
    final radius = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(color: border, width: 1.4),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: state == _OptionState.idle ? onTap : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: big ? 72 : 58),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: big
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        textAlign: big ? TextAlign.center : TextAlign.start,
                        style: big
                            ? AppText.display(24, color: fg)
                            : AppText.body(
                                16,
                                weight: FontWeight.w700,
                                color: fg,
                              ),
                      ),
                    ),
                    if (!big && state == _OptionState.correct) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.check_circle_rounded, size: 20, color: fg),
                    ],
                    if (!big && state == _OptionState.wrong) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.cancel_rounded, size: 20, color: fg),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpellingInput extends StatelessWidget {
  const _SpellingInput({
    required this.controller,
    required this.focus,
    required this.enabled,
    required this.result,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool enabled;

  /// null = not answered yet.
  final bool? result;
  final VoidCallback onSubmit;

  void _insert(String ch) {
    final sel = controller.selection;
    final text = controller.text;
    final start = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, ch),
      selection: TextSelection.collapsed(offset: start + ch.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = result == null
        ? AppColors.mustard
        : result!
        ? AppColors.mustard
        : AppColors.coral;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: result == null
            ? AppColors.navyLine.withValues(alpha: 0.6)
            : color,
        width: result == null ? 1 : 1.6,
      ),
    );
    return Column(
      children: [
        TextField(
          controller: controller,
          focusNode: focus,
          enabled: enabled,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          cursorColor: AppColors.mustard,
          style: AppText.display(26, color: AppColors.cream),
          decoration: InputDecoration(
            hintText: 'Type here',
            hintStyle: AppText.display(
              22,
              weight: FontWeight.w500,
              color: AppColors.cream.withValues(alpha: 0.25),
            ),
            filled: true,
            fillColor: AppColors.navy800.withValues(alpha: 0.6),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.mustard,
                width: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Most Indian phone keyboards have no umlauts: one tap here.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final ch in ['ä', 'ö', 'ü', 'ß'])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Material(
                  color: AppColors.cream.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled ? () => _insert(ch) : null,
                    child: SizedBox(
                      width: 52,
                      height: 46,
                      child: Center(
                        child: Text(
                          ch,
                          style: AppText.display(20, color: AppColors.cream),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (enabled) ...[
          const SizedBox(height: 16),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, v, _) => PrimaryButton(
              label: 'Check',
              onPressed: v.text.trim().isEmpty ? null : onSubmit,
            ),
          ),
        ],
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({
    super.key,
    required this.right,
    required this.question,
    required this.last,
    required this.onContinue,
  });

  final bool right;
  final Question question;
  final bool last;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final w = question.word;
    final german = [w.article, w.word].where((s) => s.isNotEmpty).join(' ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.navy950,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: (right ? AppColors.mustard : AppColors.coral).withValues(
              alpha: 0.6,
            ),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                right ? Icons.check_circle_rounded : Icons.info_rounded,
                color: right ? AppColors.mustard : AppColors.coral,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  right ? 'Richtig!' : 'Nicht ganz',
                  style: AppText.display(
                    22,
                    color: right ? AppColors.mustard : AppColors.coral,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              text: '$german  ',
              style: AppText.body(
                16,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
              children: [
                TextSpan(
                  text: w.meaning,
                  style: AppText.body(15, color: AppColors.creamMuted),
                ),
              ],
            ),
          ),
          if (w.hasExample) ...[
            const SizedBox(height: 4),
            Text(
              w.example,
              style: AppText.body(
                14,
                color: AppColors.creamMuted,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          PrimaryButton(
            label: last ? 'See results' : 'Continue',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _QuizSummary extends StatelessWidget {
  const _QuizSummary({
    super.key,
    required this.mode,
    required this.correct,
    required this.total,
    required this.onAgain,
    required this.onDone,
  });

  final PracticeMode mode;
  final int correct;
  final int total;
  final VoidCallback onAgain;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : correct / total;
    final (title, line) = ratio >= 0.9
        ? ('Ausgezeichnet!', 'Excellent, nearly perfect.')
        : ratio >= 0.6
        ? ('Gut gemacht!', 'Well done, keep practising.')
        : ('Weiter üben!', 'Keep going: every try helps you remember.');
    return FillOrScroll(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      children: [
        const Spacer(),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => SizedBox.square(
            dimension: 132,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: v,
                  strokeWidth: 10,
                  strokeCap: StrokeCap.round,
                  color: AppColors.mustard,
                  backgroundColor: AppColors.cream.withValues(alpha: 0.08),
                ),
                Center(
                  child: Text(
                    '$correct/$total',
                    style: AppText.display(32, color: AppColors.cream),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(title, style: AppText.display(30, color: AppColors.cream)),
        const SizedBox(height: 6),
        Text(
          '${mode.title} · $line',
          textAlign: TextAlign.center,
          style: AppText.body(15, color: AppColors.creamMuted, height: 1.4),
        ),
        const Spacer(flex: 2),
        PrimaryButton(label: 'Practise again', onPressed: onAgain),
        const SizedBox(height: 6),
        TextButton(
          onPressed: onDone,
          style: TextButton.styleFrom(foregroundColor: AppColors.cream),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Nothing to practise yet',
            style: AppText.display(24, color: AppColors.cream),
          ),
          const SizedBox(height: 8),
          Text(
            'Learn a few words first, then come back.',
            textAlign: TextAlign.center,
            style: AppText.body(15, color: AppColors.creamMuted),
          ),
          const SizedBox(height: 24),
          PrimaryButton(label: 'OK', onPressed: onClose),
        ],
      ),
    );
  }
}
