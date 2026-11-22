import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../shared/widgets/app_background.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../lesson/lesson_screen.dart';
import '../practice/quiz_screen.dart';
import '../words/word_row.dart';

/// One topic (or career pack): progress, learn, practise, word list.
class TopicScreen extends StatefulWidget {
  const TopicScreen({super.key, required this.topic, this.sessionSize = 10});

  final Topic topic;
  final int sessionSize;

  static Route<void> route(Topic topic, {int sessionSize = 10}) =>
      MaterialPageRoute<void>(
        builder: (_) => TopicScreen(topic: topic, sessionSize: sessionSize),
      );

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  int? _open;

  Future<void> _choosePractice() async {
    final mode = await showModalBottomSheet<PracticeMode>(
      context: context,
      backgroundColor: AppColors.navy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  'Practise ${widget.topic.english}',
                  style: AppText.display(22, color: AppColors.cream),
                ),
              ),
              for (final m in [
                PracticeMode.meaning,
                PracticeMode.article,
                PracticeMode.listening,
                PracticeMode.spelling,
              ])
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(m.icon, color: AppColors.mustard),
                  title: Text(
                    m.title,
                    style: AppText.body(
                      16,
                      weight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  subtitle: Text(
                    m.subtitle,
                    style: AppText.body(13.5, color: AppColors.creamMuted),
                  ),
                  onTap: () => Navigator.of(context).pop(m),
                ),
            ],
          ),
        ),
      ),
    );
    if (mode != null && mounted) {
      await Navigator.of(context)
          .push(QuizScreen.route(context, mode, topic: widget.topic));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.topic;
    final progress = ProgressScope.of(context);
    final words = progress.wordsFor(t).toList();
    final learned = progress.learnedIn(t);
    final next = progress.nextNewWords(widget.sessionSize, topic: t);
    final ratio = words.isEmpty ? 0.0 : learned / words.length;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 24, 0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.cream,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.mustard.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  t.icon,
                                  color: AppColors.mustard,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (t.isPack)
                                      Text(
                                        'CAREER PACK',
                                        style: AppText.body(
                                          11.5,
                                          weight: FontWeight.w800,
                                          color: AppColors.mustard,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    Text(
                                      t.german,
                                      style: AppText.display(
                                        28,
                                        color: AppColors.cream,
                                        height: 1.1,
                                      ),
                                    ),
                                    Text(
                                      t.english,
                                      style: AppText.body(
                                        14.5,
                                        color: AppColors.creamMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: ratio),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 8,
                                    color: AppColors.mustard,
                                    backgroundColor: AppColors.cream.withValues(
                                      alpha: 0.08,
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$learned of ${words.length} words learned',
                            style: AppText.body(
                              13.5,
                              weight: FontWeight.w700,
                              color: AppColors.creamMuted,
                            ),
                          ),
                          const SizedBox(height: 20),
                          PrimaryButton(
                            label: next.isEmpty
                                ? 'All learned'
                                : 'Learn ${next.length} new words',
                            onPressed: next.isEmpty
                                ? null
                                : () =>
                                      Navigator.of(context)
                                          .push(LessonScreen.route(next)),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _choosePractice,
                              icon: const Icon(Icons.bolt_rounded, size: 20),
                              label: const Text('Practise this topic'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.cream,
                                side: BorderSide(
                                  color: AppColors.cream.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                textStyle: AppText.body(
                                  15.5,
                                  weight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 26),
                          Text(
                            'WORDS',
                            style: AppText.body(
                              12,
                              weight: FontWeight.w800,
                              color: AppColors.creamMuted,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(24, 4, 24, bottom + 24),
                    sliver: SliverList.separated(
                      itemCount: words.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.navyLine.withValues(alpha: 0.35),
                      ),
                      itemBuilder: (context, i) => WordRow(
                        word: words[i],
                        progress: progress.progressOf(words[i]),
                        open: _open == i,
                        onTap: () =>
                            setState(() => _open = _open == i ? null : i),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
