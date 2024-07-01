import 'package:flutter/material.dart';
import 'package:web_socket_test/models/chat_message.dart';
import 'package:web_socket_test/pages/chat_room_page.dart';

class Messages extends StatelessWidget {
  const Messages({
    super.key,
    required ScrollController scrollController,
    required this.messages,
    required this.widget,
  }) : _scrollController = scrollController;

  final ScrollController _scrollController;
  final List<ChatMessage> messages;
  final ChatRoomPage widget;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMyMessage = message.sender == widget.userID;
        final isImage = message.type == 'image';
        return Align(
          alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMyMessage ? Colors.green[300] : Colors.blue[300],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Text(
                    message.sender,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                if (isImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      message.content,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 100,
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    ),
                  )
                else
                  Text(message.content),
              ],
            ),
          ),
        );
      },
    );
  }
}
