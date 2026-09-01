import 'package:poppylo/models/chat_models.dart';
import 'package:poppylo/services/chat_api.dart';

ChatParticipant sampleParticipant({
  String id = 'u2',
  String name = 'Ben',
  String? photo,
}) =>
    ChatParticipant(id: id, name: name, profileImage: photo);

ChatMessage msg({
  required String id,
  required String senderId,
  required String text,
  DateTime? at,
  DateTime? readAt,
}) =>
    ChatMessage(
      id: id,
      senderId: senderId,
      text: text,
      createdAt: at ?? DateTime.now(),
      readAt: readAt,
    );

/// Scriptable test double for [ChatApi].
class FakeChatApi implements ChatApi {
  FakeChatApi({
    List<ChatMessage>? messages,
    this.conversation,
    this.chatList = const [],
    this.getError,
    this.sendError,
  }) : _messages = messages ?? [];

  final List<ChatMessage> _messages; // oldest -> newest
  ChatConversation? conversation;
  List<ChatSummary> chatList;

  /// Thrown by getChat / getMessages.
  Object? getError;

  /// Thrown by sendMessage.
  Object? sendError;

  int markReadCalls = 0;
  int sendCalls = 0;
  final List<String> sentTexts = [];

  @override
  Future<List<ChatSummary>> listChats() async => chatList;

  @override
  Future<ChatConversation> getChat(String matchId) async {
    if (getError != null) throw getError!;
    return conversation ??
        ChatConversation(
          id: 'chat-$matchId',
          matchId: matchId,
          participant: sampleParticipant(),
        );
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String matchId, {
    int page = 1,
    int limit = 50,
  }) async {
    if (getError != null) throw getError!;
    // The real API returns newest-first.
    return _messages.reversed.toList();
  }

  @override
  Future<ChatMessage> sendMessage(String matchId, String text) async {
    sendCalls++;
    sentTexts.add(text);
    if (sendError != null) throw sendError!;
    final m = msg(
      id: 'srv-${_messages.length}',
      senderId: 'u1',
      text: text,
      at: DateTime.now(),
    );
    _messages.add(m);
    return m;
  }

  @override
  Future<int> markRead(String matchId) async {
    markReadCalls++;
    return 0;
  }
}
