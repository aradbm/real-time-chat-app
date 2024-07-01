class ChatMessage {
  final String sender;
  final String content;
  final String type;
  final DateTime timestamp;
  final String id;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.id,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'],
      content: json['content'],
      type: json['type'],
      timestamp: DateTime.parse(json['timestamp']),
      id: json['_id'],
    );
  }
}
