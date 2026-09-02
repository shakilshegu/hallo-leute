import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:poppylo/models/cafe_models.dart'
    show MeetingDetails, prettyClock;
import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/router/routes.dart';
import 'package:poppylo/state/cafe_controller.dart' show meetingDetailsProvider;
import 'package:poppylo/state/chat_controller.dart';
import 'package:poppylo/state/profile_controller.dart';
import 'package:poppylo/widgets/conversation_starters_sheet.dart';

const _ink = Color(0xFF1D3D33);
const _bg = Color(0xFFF8F9F8);

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.matchId, this.meetingId})
      : assert(matchId != null || meetingId != null,
            'ChatScreen needs a matchId or a meetingId');

  /// Preferred — from the Chats tab, or resolved from the meeting.
  final String? matchId;

  /// When opened from the meeting flow: unlocks the status pill + safety tools.
  final String? meetingId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _poll;
  Timer? _lockedExit;
  bool _leftLocked = false;

  String? get _directMatchId => widget.matchId;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) {
      final id = _resolvedMatchId();
      if (id != null) {
        ref.read(chatControllerProvider(id).notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _lockedExit?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// matchId directly, or from the meeting once it has loaded.
  String? _resolvedMatchId() {
    if (_directMatchId != null) return _directMatchId;
    return ref
        .read(meetingDetailsProvider(widget.meetingId!))
        .valueOrNull
        ?.matchId;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> _send(String matchId) async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    final ok =
        await ref.read(chatControllerProvider(matchId).notifier).send(text);
    if (!mounted) return;
    if (ok) {
      _input.clear();
    } else {
      final msg = ref.read(chatControllerProvider(matchId)).errorMessage;
      if (msg != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
    _scrollToBottom();
  }

  Future<void> _openStarters() async {
    final prompt = await showConversationStartersSheet(context);
    if (prompt != null && mounted) {
      final base = _input.text.trimRight();
      _input.text = base.isEmpty ? prompt : '$base $prompt';
      _input.selection = TextSelection.collapsed(offset: _input.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the matchId (directly, or via the meeting).
    if (_directMatchId == null) {
      final meetingAsync = ref.watch(meetingDetailsProvider(widget.meetingId!));
      return meetingAsync.when(
        loading: () => const _ChatScaffold(child: _CenterSpinner()),
        error: (_, __) => _ChatScaffold(
          child: _ChatMessageState(
            icon: Icons.error_outline,
            title: 'Chat not found.',
            onBack: () => context.pop(),
          ),
        ),
        data: (meeting) => _build(context, meeting.matchId),
      );
    }
    return _build(context, _directMatchId!);
  }

  Widget _build(BuildContext context, String matchId) {
    final chat = ref.watch(chatControllerProvider(matchId));
    final meAsync = ref.watch(meProvider);
    final myId = meAsync.valueOrNull?.id;
    // Only block bubble rendering while we're genuinely still waiting for the
    // profile — never on an error (that would strand the thread on a spinner).
    final myIdPending = myId == null && meAsync.isLoading;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // 403 → don't let the user stay here.
    if (chat.phase == ChatPhase.locked && !_leftLocked) {
      _leftLocked = true;
      _poll?.cancel();
      _lockedExit ??= Timer(const Duration(milliseconds: 2200), () {
        if (mounted && context.canPop()) context.pop();
      });
    }

    ref.listen(chatControllerProvider(matchId), (prev, next) {
      if (prev?.messages.length != next.messages.length) _scrollToBottom();
    });

    final title = chat.conversation?.participant.name ?? 'Chat';

    return Scaffold(
      backgroundColor: _bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: _ink,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.pop();
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      title,
                      style: textTheme.titleMedium?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (widget.meetingId != null)
                  IconButton(
                    icon: const Icon(Icons.shield_outlined),
                    color: _ink,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      context.push(AppRoutes.safetyPath(widget.meetingId!));
                    },
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: _ink),
                  onSelected: (value) {
                    if (value == 'home') {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.home);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'home', child: Text('Back to home')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          if (widget.meetingId != null) _meetingPill(),
          const SizedBox(height: 16),
          Expanded(child: _bodyFor(context, chat, myId, myIdPending, matchId)),
          _inputBar(context, matchId, chat.sending),
        ],
      ),
    );
  }

  Widget _meetingPill() {
    final meeting =
        ref.watch(meetingDetailsProvider(widget.meetingId!)).valueOrNull;
    if (meeting == null) return const SizedBox.shrink();
    final day = _pillDate(meeting).substring(0, 3).toUpperCase();
    final time = prettyClock(meeting.startTime).replaceAll(':00', '');
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFE6EBE6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'COFFEE · $day $time · ${meeting.cafe.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _ink.withOpacity(0.7),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
        ),
      ),
    );
  }

  String _pillDate(MeetingDetails m) {
    final dt = DateTime.tryParse('${m.date}T${m.startTime}:00');
    if (dt == null) return m.date;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[dt.weekday - 1];
  }

  Widget _bodyFor(BuildContext context, ChatState chat, String? myId,
      bool myIdPending, String matchId) {
    switch (chat.phase) {
      case ChatPhase.loading:
        return const _CenterSpinner();
      case ChatPhase.locked:
        return _ChatMessageState(
          icon: Icons.lock_outline,
          title: 'Chat becomes available once your match is confirmed.',
          onBack: () => context.pop(),
        );
      case ChatPhase.notFound:
        return _ChatMessageState(
          icon: Icons.chat_bubble_outline,
          title: 'Chat not found.',
          onBack: () => context.pop(),
        );
      case ChatPhase.error:
        return _ChatMessageState(
          icon: Icons.cloud_off_outlined,
          title: chat.errorMessage ?? 'Something went wrong. Please try again.',
          actionLabel: 'Retry',
          onAction: () {
            final id = _resolvedMatchId();
            if (id != null) {
              ref.read(chatControllerProvider(id).notifier).load();
            }
          },
          onBack: () => context.pop(),
        );
      case ChatPhase.ready:
        // Wait for our own id before drawing bubbles — otherwise every message
        // (including the ones we just sent) briefly renders on the wrong side.
        if (myIdPending) return const _CenterSpinner();
        if (chat.messages.isEmpty) return const _EmptyChat();
        final msgs = chat.messages;
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          itemCount: msgs.length,
          itemBuilder: (context, i) {
            final m = msgs[i];
            // A message is "mine" if the server says so, or if it's still a
            // local optimistic / failed bubble (which are always ours).
            final mine =
                (myId != null && m.senderId == myId) || m.pending || m.failed;
            final prev = i > 0 ? msgs[i - 1] : null;
            final newDay =
                prev == null || !_sameDay(prev.createdAt, m.createdAt);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (newDay) _daySeparator(context, m.createdAt),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: mine
                      ? _outgoing(context, m, matchId)
                      : _incoming(context, m),
                ),
              ],
            );
          },
        );
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _daySeparator(BuildContext context, DateTime when) {
    final now = DateTime.now();
    final label = _sameDay(when, now)
        ? 'TODAY'
        : _sameDay(when, now.subtract(const Duration(days: 1)))
            ? 'YESTERDAY'
            : '${_dayName(when)}, ${when.day}/${when.month}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _ink.withOpacity(0.4),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
        ),
      ),
    );
  }

  String _dayName(DateTime d) => const [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][d.weekday - 1];

  // --- message bubbles --------------------------------------------

  Widget _incoming(BuildContext context, ChatMessage m) {
    final textTheme = Theme.of(context).textTheme;
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    // 1:1 thread — the header already names who this is, so no per-bubble avatar.
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9EDE9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  child: Text(
                    m.text,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: _ink, height: 1.35),
                  ),
                ),
              ),
              _stamp(context, m, alignEnd: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _outgoing(BuildContext context, ChatMessage m, String matchId) {
    final theme = Theme.of(context);
    final maxW = MediaQuery.sizeOf(context).width * 0.72;
    final bubble = Opacity(
      opacity: m.pending ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: m.failed ? Colors.redAccent : theme.colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(
          m.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            height: 1.35,
          ),
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: m.failed
                    ? GestureDetector(
                        onTap: () => ref
                            .read(chatControllerProvider(matchId).notifier)
                            .retry(m),
                        child: bubble,
                      )
                    : bubble,
              ),
              _stamp(context, m, alignEnd: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stamp(BuildContext context, ChatMessage m, {required bool alignEnd}) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: _ink.withOpacity(0.4),
          fontSize: 10,
        );
    final label = m.failed
        ? 'Not sent · tap to retry'
        : m.pending
            ? 'Sending…'
            : formatChatTime(m.createdAt);
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: alignEnd ? 0 : 4,
        right: alignEnd ? 4 : 0,
      ),
      child: Text(label, style: style),
    );
  }

  // --- input bar (existing design) -------------------------------

  Widget _inputBar(BuildContext context, String matchId, bool sending) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: 'Conversation starters',
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _openStarters,
                  child: Icon(Icons.lightbulb_outline,
                      color: _ink.withOpacity(0.5)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (_input.text.trim().isNotEmpty && !sending) {
                      _send(matchId);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Write a message...',
                    hintStyle: textTheme.bodyMedium
                        ?.copyWith(color: _ink.withOpacity(0.4)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: textTheme.bodyMedium?.copyWith(color: _ink),
                ),
              ),
              const SizedBox(width: 12),
              // Only this rebuilds as you type — not the whole message list.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _input,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty && !sending;
                  return GestureDetector(
                    onTap: canSend ? () => _send(matchId) : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: canSend
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withOpacity(0.35),
                        shape: BoxShape.circle,
                      ),
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.arrow_upward,
                              color: theme.colorScheme.onPrimary, size: 20),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- shared bits -----------------------------------------------------

class _ChatScaffold extends StatelessWidget {
  const _ChatScaffold({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: _ink),
            onPressed: () => context.pop(),
          ),
        ),
        body: child,
      );
}

class _CenterSpinner extends StatelessWidget {
  const _CenterSpinner();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _ink));
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start the conversation ☕',
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: _ink,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hello and make your coffee meet a little easier.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: _ink.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageState extends StatelessWidget {
  const _ChatMessageState({
    required this.icon,
    required this.title,
    this.actionLabel,
    this.onAction,
    required this.onBack,
  });

  final IconData icon;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: _ink),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: _ink, height: 1.4),
            ),
            const SizedBox(height: 20),
            if (actionLabel != null)
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            TextButton(onPressed: onBack, child: const Text('Go back')),
          ],
        ),
      ),
    );
  }
}
