import 'package:web_socket_test/models/chat_message.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final DateTime createdAt;
  DateTime updatedAt;
  ChatMessage? lastMessage;
  bool isUnread;
  List<ChatMessage> messages = [];

  ChatRoom({
    required this.id,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessage,
    this.isUnread = false,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'],
      participants: List<String>.from(json['participants']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
    );
  }

  void addMessage(ChatMessage message) {
    messages.add(message);
    lastMessage = message;
    updatedAt = message.timestamp;
    isUnread = true;
  }
}
