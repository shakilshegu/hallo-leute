import 'package:flutter/foundation.dart';

/// coffee-meet-api `/chats` contract (see `src/modules/chat`).

@immutable
class ChatParticipant {
  const ChatParticipant({
    required this.id,
    required this.name,
    required this.profileImage,
  });

  final String id;
  final String name;
  final String? profileImage;

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Your match',
      profileImage: json['profileImage'] as String?,
    );
  }
}

/// `GET /chats/:matchId` → the chat header (id + the other person).
@immutable
class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.matchId,
    required this.participant,
  });

  final String id;
  final String matchId;
  final ChatParticipant participant;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final chat = json['chat'] as Map<String, dynamic>? ?? json;
    return ChatConversation(
      id: chat['id'] as String? ?? '',
      matchId: chat['matchId'] as String? ?? '',
      participant: ChatParticipant.fromJson(
        chat['participant'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.readAt,
    this.pending = false,
    this.failed = false,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final DateTime? readAt;

  /// UI-only: an optimistically-added message still in flight / that failed.
  final bool pending;
  final bool failed;

  ChatMessage copyWith({bool? pending, bool? failed}) => ChatMessage(
        id: id,
        senderId: senderId,
        text: text,
        createdAt: createdAt,
        readAt: readAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
      );

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? ''),
    );
  }
}

/// One row in `GET /chats` (the Chats tab).
@immutable
class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.matchId,
    required this.participant,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String chatId;
  final String matchId;
  final ChatParticipant participant;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  factory ChatSummary.fromJson(Map<String, dynamic> json) {
    return ChatSummary(
      chatId: json['chatId'] as String? ?? '',
      matchId: json['matchId'] as String? ?? '',
      participant: ChatParticipant.fromJson(
        json['participant'] as Map<String, dynamic>? ?? const {},
      ),
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? ''),
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// "5:00 PM" / "Yesterday" / "Mon" / "12 Aug" — compact chat timestamp.
String formatChatTime(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final sameDay = local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) {
    var h = local.hour;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12;
    if (h == 0) h = 12;
    return '$h:$m $ampm';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day) {
    return 'Yesterday';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  if (now.difference(local).inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[local.weekday - 1];
  }
  return '${local.day} ${months[local.month - 1]}';
}
