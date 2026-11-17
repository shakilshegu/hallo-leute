import 'package:flutter/material.dart';

import '../../data/progress.dart';
import '../../data/vocabulary.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'word_row.dart';

/// The vocabulary library: search, filter by topic, tap a word for an example.
class WordsTab extends StatefulWidget {
  const WordsTab({
    super.key,
    required this.topic,
    required this.onTopicChanged,
  });

  /// Active topic filter; null shows every word.
  final Topic? topic;
  final ValueChanged<Topic?> onTopicChanged;

  @override
  State<WordsTab> createState() => _WordsTabState();
}

class _WordsTabState extends State<WordsTab> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _query = '';
  int? _openIndex;

  /// false = every word, true = only words this learner has learned.
  bool _mine = false;

  @override
  void didUpdateWidget(WordsTab old) {
    super.didUpdateWidget(old);
    if (old.topic != widget.topic) {
      _openIndex = null;
      _toTop();
    }
  }

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

  void _setMine(bool mine) {
    if (mine == _mine) return;
    setState(() {
      _mine = mine;
      _openIndex = null;
    });
    _toTop();
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final learned = progress.learnedWords;
    final topicWords = widget.topic?.words.toSet();
    final words = (_mine ? learned : vocabulary)
        .where((w) => widget.topic == null || topicWords!.contains(w))
        .where((w) => w.matches(_query))
        .toList();
    final bottomInset = MediaQuery.paddingOf(context).bottom;

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
                mine: _mine,
                allCount: vocabulary.length,
                mineCount: learned.length,
                onChanged: _setMine,
              ),
              const SizedBox(height: 12),
              _SearchField(
                controller: _search,
                onChanged: (v) {
                  setState(() {
                    _query = v;
                    _openIndex = null;
                  });
                  _toTop();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _TopicChip(
                label: 'All',
                selected: widget.topic == null,
                onTap: () => widget.onTopicChanged(null),
              ),
              for (final t in Topic.values)
                _TopicChip(
                  label: t.english,
                  selected: widget.topic == t,
                  onTap: () => widget.onTopicChanged(t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: words.isEmpty
              ? _EmptyState(
                  query: _query,
                  noneLearned: _mine && learned.isEmpty,
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

/// "All words · 3014 | My words · 25" segmented switch.
class _ScopeSwitch extends StatelessWidget {
  const _ScopeSwitch({
    required this.mine,
    required this.allCount,
    required this.mineCount,
    required this.onChanged,
  });

  final bool mine;
  final int allCount;
  final int mineCount;
  final ValueChanged<bool> onChanged;

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
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: Container(
                width: c.maxWidth / 2,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            Row(
              children: [
                _segment('All words', allCount, !mine, () => onChanged(false)),
                _segment('My words', mineCount, mine, () => onChanged(true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int count, bool selected, VoidCallback onTap) {
    final color = selected ? AppColors.navy : AppColors.cream;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: Text.rich(
              TextSpan(
                text: label,
                style: AppText.body(14, weight: FontWeight.w800, color: color),
                children: [
                  TextSpan(
                    text: '  $count',
                    style: AppText.body(
                      13,
                      weight: FontWeight.w600,
                      color: selected
                          ? AppColors.navy700
                          : AppColors.creamMuted,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
