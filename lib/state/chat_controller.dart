import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/chat_api.dart';
import 'package:poppylo/state/profile_controller.dart';

export 'package:poppylo/services/chat_api.dart' show ChatApi, chatApiProvider;

/// The Chats tab list (`GET /chats`).
final chatListProvider = FutureProvider.autoDispose<List<ChatSummary>>((ref) {
  return ref.watch(chatApiProvider).listChats();
});

enum ChatPhase { loading, ready, locked, notFound, error }

@immutable
class ChatState {
  const ChatState({
    this.phase = ChatPhase.loading,
    this.conversation,
    this.messages = const [],
    this.errorMessage,
    this.sending = false,
  });

  final ChatPhase phase;
  final ChatConversation? conversation;

  /// Oldest → newest, ready for a bottom-anchored list.
  final List<ChatMessage> messages;
  final String? errorMessage;
  final bool sending;

  bool get isEmpty => phase == ChatPhase.ready && messages.isEmpty;

  ChatState copyWith({
    ChatPhase? phase,
    ChatConversation? conversation,
    List<ChatMessage>? messages,
    Object? errorMessage = _sentinel,
    bool? sending,
  }) {
    return ChatState(
      phase: phase ?? this.phase,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      sending: sending ?? this.sending,
    );
  }

  static const _sentinel = Object();
}

class ChatController extends StateNotifier<ChatState> {
  ChatController(this._ref, this._matchId) : super(const ChatState()) {
    load();
  }

  final Ref _ref;
  final String _matchId;

  ChatApi get _api => _ref.read(chatApiProvider);
  String get _myUserId => _ref.read(meProvider).valueOrNull?.id ?? '';

  Future<void> load() async {
    if (state.messages.isEmpty) {
      state = state.copyWith(phase: ChatPhase.loading, errorMessage: null);
    }
    try {
      final conversation = await _api.getChat(_matchId);
      final newestFirst = await _api.getMessages(_matchId, page: 1, limit: 50);
      state = state.copyWith(
        phase: ChatPhase.ready,
        conversation: conversation,
        messages: newestFirst.reversed.toList(),
        errorMessage: null,
      );
      unawaited(_safeMarkRead());
    } catch (error) {
      state = state.copyWith(
        phase: _phaseFor(error),
        errorMessage: chatErrorMessage(error),
      );
    }
  }

  /// Poll target — pulls new messages without disturbing the screen.
  Future<void> refresh() async {
    if (state.phase != ChatPhase.ready) return;
    try {
      final newestFirst = await _api.getMessages(_matchId, page: 1, limit: 50);
      final server = newestFirst.reversed.toList();
      final serverIds = server.map((m) => m.id).toSet();
      // Keep any local optimistic/failed message the server hasn't stored.
      final extras = state.messages
          .where((m) => (m.pending || m.failed) && !serverIds.contains(m.id));
      state = state.copyWith(messages: [...server, ...extras]);
      unawaited(_safeMarkRead());
    } catch (_) {
      // Transient — keep showing what we have.
    }
  }

  Future<bool> send(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || state.sending) return false;

    final tempId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: tempId,
      senderId: _myUserId,
      text: text,
      createdAt: DateTime.now(),
      readAt: null,
      pending: true,
    );
    state = state.copyWith(
      sending: true,
      messages: [...state.messages, optimistic],
      errorMessage: null,
    );

    try {
      final saved = await _api.sendMessage(_matchId, text);
      state = state.copyWith(
        sending: false,
        messages: [
          for (final m in state.messages) m.id == tempId ? saved : m,
        ],
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        sending: false,
        errorMessage: chatErrorMessage(error),
        messages: [
          for (final m in state.messages)
            m.id == tempId ? m.copyWith(pending: false, failed: true) : m,
        ],
      );
      return false;
    }
  }

  Future<void> _safeMarkRead() async {
    try {
      await _api.markRead(_matchId);
    } catch (_) {}
  }

  ChatPhase _phaseFor(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 403) return ChatPhase.locked;
      if (error.statusCode == 404) return ChatPhase.notFound;
    }
    return ChatPhase.error;
  }
}

final chatControllerProvider =
    StateNotifierProvider.family<ChatController, ChatState, String>(
        (ref, matchId) {
  return ChatController(ref, matchId);
});

/// User-facing copy for a failed chat call.
String chatErrorMessage(Object error) {
  if (error is ApiException) {
    switch (error.statusCode) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'Chat is available after your match is confirmed.';
      case 404:
        return 'Chat not found.';
      case 0:
        return 'Unable to send message. Please try again.';
      case 500:
        return 'Something went wrong. Please try again.';
      default:
        return error.message;
    }
  }
  return 'Something went wrong. Please try again.';
}
