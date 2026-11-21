import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../home/widgets/home_cards.dart';
import '../topics/topic_screen.dart';
import 'word_row.dart';

/// The vocabulary library.
///
/// * **All words**: search, filter by All / Learned / To learn, tap a word
///   for its plural, example and history.
/// * **Categories**: career packs ("For your job") and every topic.
class WordsTab extends StatefulWidget {
  const WordsTab({super.key, this.sessionSize = 10});

  /// Words per "learn new words" session on a topic page.
  final int sessionSize;

  @override
  State<WordsTab> createState() => _WordsTabState();
}

enum _Filter { all, learned, toLearn }

class _WordsTabState extends State<WordsTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  int? _openIndex;
  bool _categories = false;
  _Filter _filter = _Filter.all;

  /// New filter or search → show results from the top.
  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _setFilter(_Filter f) {
    if (f == _filter) return;
    setState(() {
      _filter = f;
      _openIndex = null;
    });
    _toTop();
  }

  void _openTopic(Topic t) =>
      Navigator.of(context)
          .push(TopicScreen.route(t, sessionSize: widget.sessionSize));

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final learnedCount = progress.totalLearned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Words', style: AppText.display(28, color: AppColors.cream)),
              const SizedBox(height: 14),
              _ScopeSwitch(
                labels: const ['All words', 'Categories'],
                index: _categories ? 1 : 0,
                onChanged: (i) => setState(() {
                  _categories = i == 1;
                  _openIndex = null;
                }),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _categories
                ? _Categories(
                    key: const ValueKey('categories'),
                    onOpen: _openTopic,
                  )
                : _allWords(progress, learnedCount),
          ),
        ),
      ],
    );
  }

  Widget _allWords(LearningProgress progress, int learnedCount) {
    final source = switch (_filter) {
      _Filter.all => vocabulary,
      _Filter.learned => progress.learnedWords,
      _Filter.toLearn => vocabulary.where((w) => !progress.isLearned(w)),
    };
    final words = source.where((w) => w.matches(_query)).toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      key: const ValueKey('all'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: _SearchField(
            controller: _search,
            onChanged: (v) {
              setState(() {
                _query = v;
                _openIndex = null;
              });
              _toTop();
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _TopicChip(
                label: 'All · ${vocabulary.length}',
                selected: _filter == _Filter.all,
                onTap: () => _setFilter(_Filter.all),
              ),
              _TopicChip(
                label: 'Learned · $learnedCount',
                selected: _filter == _Filter.learned,
                onTap: () => _setFilter(_Filter.learned),
              ),
              _TopicChip(
                label: 'To learn · ${vocabulary.length - learnedCount}',
                selected: _filter == _Filter.toLearn,
                onTap: () => _setFilter(_Filter.toLearn),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: words.isEmpty
              ? _EmptyState(
                  query: _query,
                  noneLearned: _filter == _Filter.learned && learnedCount == 0,
                )
              : ListView.separated(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(24, 4, 24, bottomInset + 24),
                  itemCount: words.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: AppColors.navyLine.withValues(alpha: 0.35),
                  ),
                  itemBuilder: (context, i) => WordRow(
                    word: words[i],
                    progress: progress.progressOf(words[i]),
                    open: _openIndex == i,
                    onTap: () =>
                        setState(() => _openIndex = _openIndex == i ? null : i),
                  ),
                ),
        ),
      ],
    );
  }
}

/// Career packs plus every topic, each with its progress.
class _Categories extends StatelessWidget {
  const _Categories({super.key, required this.onOpen});

  final ValueChanged<Topic> onOpen;

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
      children: [
        const SectionLabel('For your job'),
        const SizedBox(height: 12),
        for (final t in Topic.packs) ...[
          PackCard(
            topic: t,
            learned: progress.learnedIn(t),
            onTap: () => onOpen(t),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        SectionLabel('Topics', trailing: '${Topic.general.length} categories'),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            const gap = 10.0;
            final w = (c.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final t in Topic.general)
                  SizedBox(
                    width: w,
                    child: _CategoryTile(
                      topic: t,
                      learned: progress.learnedIn(t),
                      onTap: () => onOpen(t),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.topic,
    required this.learned,
    required this.onTap,
  });

  final Topic topic;
  final int learned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = topic.wordCount;
    return Pressable(
      onTap: onTap,
      semanticLabel: '${topic.english}, ${topic.german}. $learned of $total',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navy800.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.navyLine.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(topic.icon, size: 22, color: AppColors.mustard),
            const SizedBox(height: 10),
            Text(
              topic.german,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(
                14.5,
                weight: FontWeight.w800,
                color: AppColors.cream,
              ),
            ),
            Text(
              topic.english,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.body(12.5, color: AppColors.creamMuted),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : learned / total,
                minHeight: 4,
                color: AppColors.mustard,
                backgroundColor: AppColors.cream.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$learned / $total words',
              style: AppText.body(11.5, color: AppColors.creamMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: AppColors.navyLine.withValues(alpha: 0.5)),
    );
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.mustard,
        textInputAction: TextInputAction.search,
        style: AppText.body(
          15.5,
          weight: FontWeight.w600,
          color: AppColors.cream,
        ),
        decoration: InputDecoration(
          hintText: 'Search in German or English',
          hintStyle: AppText.body(15, color: AppColors.creamMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.creamMuted,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.creamMuted,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
          filled: true,
          fillColor: AppColors.navy800.withValues(alpha: 0.6),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.mustard, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.cream
                  : AppColors.cream.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              label,
              style: AppText.body(
                13.5,
                weight: FontWeight.w700,
                color: selected ? AppColors.navy : AppColors.cream,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query, this.noneLearned = false});

  final String query;
  final bool noneLearned;

  @override
  Widget build(BuildContext context) {
    if (noneLearned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.menu_book_outlined,
                size: 36,
                color: AppColors.mustard,
              ),
              const SizedBox(height: 12),
              Text(
                'Noch keine Wörter',
                style: AppText.display(20, color: AppColors.cream),
              ),
              const SizedBox(height: 4),
              Text(
                'No words yet. Words you learn in lessons will appear here.',
                textAlign: TextAlign.center,
                style: AppText.body(14, color: AppColors.creamMuted),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppColors.creamMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'Keine Treffer',
              style: AppText.display(20, color: AppColors.cream),
            ),
            const SizedBox(height: 4),
            Text(
              query.isEmpty
                  ? 'No words in this topic yet.'
                  : 'No results for "$query".',
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.creamMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-way segmented switch with a sliding cream highlight.
class _ScopeSwitch extends StatelessWidget {
  const _ScopeSwitch({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            AnimatedAlign(
              alignment: index == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              child: Container(
                width: c.maxWidth / labels.length,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(i),
                        child: Center(
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              14,
                              weight: FontWeight.w800,
                              color: i == index
                                  ? AppColors.navy
                                  : AppColors.cream,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
