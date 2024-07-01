import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_test/models/chat_room.dart';
import 'package:web_socket_test/pages/chat_room_page.dart';
import 'package:web_socket_test/pages/home_page.dart';
import '../models/chat_message.dart';
import '../websocket_service.dart';

class MainChatPage extends StatefulWidget {
  final WebSocketService websocketService;
  final String userID;
  final String username;

  const MainChatPage({
    super.key,
    required this.websocketService,
    required this.userID,
    required this.username,
  });

  @override
  State<MainChatPage> createState() => _MainChatPageState();
}

class _MainChatPageState extends State<MainChatPage> {
  List<ChatRoom> chatRooms = [];
  String? currentRoomId;

  @override
  void initState() {
    super.initState();
    widget.websocketService.addListener(_onMessageReceived);
  }

  void _onMessageReceived() {
    final message = widget.websocketService.lastMessage;
    handleWebSocketMessage(message, addNewRoom, updateChatRoom);
  }

  void addNewRoom(ChatRoom newRoom) {
    setState(() {
      chatRooms.add(newRoom);
      _sortChatRooms();
    });
  }

  void updateChatRoom(String roomId, ChatMessage newMessage) {
    setState(() {
      final roomIndex = chatRooms.indexWhere((room) => room.id == roomId);
      if (roomIndex != -1) {
        final room = chatRooms[roomIndex];
        room.addMessage(newMessage);
        room.isUnread = roomId != currentRoomId;
        chatRooms[roomIndex] = room;
        _sortChatRooms();
      }
    });
  }

  void joinRoom(String roomId) {
    widget.websocketService.joinRoom(roomId);
  }

  void _sortChatRooms() {
    chatRooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void sendTextMessage(String roomId, String message) {
    widget.websocketService.sendTextMessage(message, roomId);
  }

  void sendImageMessage(String roomId, String imageUrl) {
    widget.websocketService.sendImageMessage(imageUrl, roomId);
  }

  void handleWebSocketMessage(String message, Function(ChatRoom) addNewRoom,
      Function(String, ChatMessage) updateChatRoom) {
    final parsedMessage = jsonDecode(message);

    switch (parsedMessage['type']) {
      case 'initRooms':
        final List<dynamic> roomsData = parsedMessage['openRooms'];
        final rooms = roomsData.map((room) => ChatRoom.fromJson(room)).toList();
        rooms.forEach(addNewRoom);
        break;
      case 'createRoom':
        final newRoom = ChatRoom(
          id: parsedMessage['roomID'] ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          participants: List<String>.from(parsedMessage['participants']),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastMessage: ChatMessage(
            sender: parsedMessage['userID'],
            content: 'Room created',
            type: 'text',
            timestamp: DateTime.now(),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        );
        addNewRoom(newRoom);
        break;
      case 'sendMessage':
        final roomId = parsedMessage['roomID'];
        final newMessage = ChatMessage(
          sender: parsedMessage['userID'],
          content: parsedMessage['message'],
          type: parsedMessage['messageType'],
          timestamp: DateTime.now(),
          id: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        updateChatRoom(roomId, newMessage);
        break;
      case 'roomMessage':
        final newMessage = ChatMessage.fromJson(parsedMessage['message']);
        final roomId = parsedMessage['roomID'];
        updateChatRoom(roomId, newMessage);
        break;
      case 'leftRoom':
        final roomId = parsedMessage['roomID'];
        final roomIndex = chatRooms.indexWhere((room) => room.id == roomId);
        if (roomIndex != -1) {
          setState(() {
            chatRooms.removeAt(roomIndex);
          });
        }
        break;
      default:
        break;
    }
  }

  void _handleLogout() {
    widget.websocketService.disconnect();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => MyHomePage(
          title: 'Chat App',
          websocketService: widget.websocketService,
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _handleLogout();
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent.withOpacity(0.1), Colors.white],
          ),
        ),
        child: chatRooms.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No chat rooms available',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: chatRooms.length,
                itemBuilder: (context, index) {
                  final room = chatRooms[index];
                  final isImageMessage = room.lastMessage?.type == 'image';
                  return Card(
                    elevation: 2,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          room.participants.first[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        room.participants.join(', '),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          if (isImageMessage)
                            const Icon(Icons.image,
                                size: 16, color: Colors.grey)
                          else
                            const Icon(Icons.chat_bubble_outline,
                                size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              isImageMessage
                                  ? 'Image'
                                  : room.lastMessage?.content ?? 'No messages',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            room.updatedAt.toString().split('.')[0],
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          if (room.isUnread)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          currentRoomId = room.id;
                          room.isUnread = false;
                        });
                        joinRoom(room.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomPage(
                              websocketService: widget.websocketService,
                              userID: widget.userID,
                              username: widget.username,
                              chatRoom: room,
                              sendTextMessage: sendTextMessage,
                              sendImageMessage: sendImageMessage,
                            ),
                          ),
                        ).then((_) {
                          setState(() {
                            currentRoomId = null;
                          });
                        });
                      },
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add logic to search a room, i
          widget.websocketService.createRoom(['otherUserId']);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    widget.websocketService.removeListener(_onMessageReceived);
    super.dispose();
  }
}
