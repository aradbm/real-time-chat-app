// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:web_socket_test/models/chat_room.dart';
import 'package:web_socket_test/models/chat_message.dart';
import 'package:web_socket_test/pages/widgets/messages.dart';
import 'package:web_socket_test/websocket_service.dart';
import 'package:http/http.dart' as http;

class ChatRoomPage extends StatefulWidget {
  final WebSocketService websocketService;
  final String userID;
  final String username;
  final ChatRoom chatRoom;
  final Function(String, String) sendTextMessage;
  final Function(String, String) sendImageMessage;

  const ChatRoomPage({
    super.key,
    required this.websocketService,
    required this.userID,
    required this.username,
    required this.chatRoom,
    required this.sendTextMessage,
    required this.sendImageMessage,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> messages = [];
  bool isLoading = true;
  File? _image;
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _joinRoom();
    widget.websocketService.addListener(_onMessageReceived);

    // Add this delay to ensure scrolling works after initial load
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _joinRoom() {
    widget.websocketService.joinRoom(widget.chatRoom.id);
  }

  void _onMessageReceived() {
    final message = widget.websocketService.lastMessage;
    _handleWebSocketMessage(message);
  }

  void _handleWebSocketMessage(String message) {
    final parsedMessage = jsonDecode(message);
    switch (parsedMessage['type']) {
      case 'updatedRoom':
        final room = parsedMessage['updatedRoom'];
        final roomId = room['_id'];
        if (roomId == widget.chatRoom.id) {
          setState(() {
            messages = List<ChatMessage>.from(room['messages']
                .map((message) => ChatMessage.fromJson(message)));
            isLoading = false;
          });
          _scrollToBottom();
        }
        break;
      case 'roomMessage':
        final newMessage = ChatMessage.fromJson(parsedMessage['message']);
        if (parsedMessage['roomID'] == widget.chatRoom.id) {
          setState(() {
            messages.add(newMessage);
          });
          _scrollToBottom();
        }
        break;
    }
  }

  Future<void> _sendMessage() async {
    var imageUrl = '';
    if (_image != null) {
      try {
        // Get the upload URL from your server
        final response = await http.get(
            Uri.parse('http://10.0.2.2/api/s3-upload-url/${widget.userID}'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final uploadUrl = data['uploadUrl'];
          final key = data['key'];

          // Get the image bytes
          final imageBytes = await _image!.readAsBytes();

          // Upload the image to S3
          final uploadResponse = await http.put(
            Uri.parse(uploadUrl),
            body: imageBytes,
            headers: {'Content-Type': 'image/jpeg'},
          );

          if (uploadResponse.statusCode == 200) {
            // Construct the final image URL
            imageUrl =
                'https://swapit-item-images-original.s3.eu-north-1.amazonaws.com/$key';

            // Send the image URL to the chat room
            widget.sendImageMessage(widget.chatRoom.id, imageUrl);
            setState(() {
              _image = null;
            });
          } else {
            print('Failed to upload image: ${uploadResponse.statusCode}');
          }
        } else {
          print('Failed to get upload URL: ${response.statusCode}');
        }
      } catch (e) {
        print('Error sending image: $e');
      }
      setState(() {
        _image = null;
        if (imageUrl.isNotEmpty) {
          messages.add(
            ChatMessage(
              sender: widget.userID,
              content: imageUrl,
              type: 'image',
              timestamp: DateTime.now(),
              id: '',
            ),
          );
        }
      });
    } else if (_messageController.text.isNotEmpty) {
      widget.sendTextMessage(widget.chatRoom.id, _messageController.text);
      final chatmsg = ChatMessage(
        sender: widget.userID,
        content: _messageController.text,
        type: 'text',
        timestamp: DateTime.now(),
        id: '',
      );

      setState(() {
        messages.add(chatmsg);
      });
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? returnedImage = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (returnedImage == null) return;

    setState(() {
      _image = File(returnedImage.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.participants.join(', ')),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              widget.websocketService.leaveRoom(widget.chatRoom.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Messages(
                      scrollController: _scrollController,
                      messages: messages,
                      widget: widget),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _image == null
                            ? TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                ),
                              )
                            // else show the image preview, with X button to remove the image
                            : Row(
                                children: [
                                  // Image.file(_image!),
                                  // show image preview with 40x40 size
                                  Image.file(
                                    _image!,
                                    width: 40,
                                    height: 40,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _image = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    widget.websocketService.removeListener(_onMessageReceived);
    super.dispose();
  }
}
