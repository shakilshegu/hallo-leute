import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/services/api_client.dart';
import 'package:poppylo/services/onboarding_api.dart' show apiClientProvider;

/// coffee-meet-api `/chats` — the data/repository layer for the chat feature.
/// Widgets and controllers never touch [ApiClient] directly. The Firebase ID
/// token is attached automatically by [ApiClient].
class ChatApi {
  ChatApi(this._client);

  final ApiClient _client;

  /// `GET /chats` — the caller's conversations (one per confirmed match).
  Future<List<ChatSummary>> listChats() async {
    final rows = await _client.getList('/chats');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ChatSummary.fromJson)
        .toList();
  }

  /// `GET /chats/:matchId` — chat header + the other participant.
  /// Throws [ApiException] with statusCode 403 while the match isn't confirmed.
  Future<ChatConversation> getChat(String matchId) async {
    final data = await _client.get('/chats/$matchId');
    return ChatConversation.fromJson(data);
  }

  /// `GET /chats/:matchId/messages` — newest-first, paginated.
  Future<List<ChatMessage>> getMessages(
    String matchId, {
    int page = 1,
    int limit = 50,
  }) async {
    final rows = await _client
        .getList('/chats/$matchId/messages?page=$page&limit=$limit');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList();
  }

  /// `POST /chats/:matchId/messages`. `senderId` is never sent.
  Future<ChatMessage> sendMessage(String matchId, String text) async {
    final data =
        await _client.post('/chats/$matchId/messages', body: {'text': text});
    return ChatMessage.fromJson(data);
  }

  /// `POST /chats/:matchId/read` — marks the other person's messages read.
  Future<int> markRead(String matchId) async {
    final data = await _client.post('/chats/$matchId/read');
    return (data['updated'] as num?)?.toInt() ?? 0;
  }
}

final chatApiProvider = Provider<ChatApi>((ref) {
  return ChatApi(ref.watch(apiClientProvider));
});
