// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  String? _userID;
  String? _username;
  String _lastMessage = '';
  Timer? _reconnectTimer;
  bool _isConnecting = false;

  String get lastMessage => _lastMessage;
  String? get userID => _userID;
  String? get username => _username;

  bool get isConnected => _channel != null;

  Future<void> connect() async {
    if (isConnected || _isConnecting) return;

    _isConnecting = true;
    try {
      final wsUrl = Uri.parse('ws://10.0.2.2:8080');
      _channel = WebSocketChannel.connect(wsUrl);
      await _channel!.ready;

      _channel!.stream.listen(
        (message) {
          _lastMessage = message.toString();
          notifyListeners();
        },
        onDone: _handleDisconnection,
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
      );

      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      print('Failed to connect: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _channel = null;
    _isConnecting = false;
    notifyListeners();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), connect);
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _userID = null;
    _username = null;
    _lastMessage = '';
    _isConnecting = false;
    notifyListeners();
  }

  void initializeUser(String userID, String username) {
    _userID = userID;
    _username = username;
    final jsonMessage = {
      "type": "init",
      "userID": userID,
      "username": username,
      "photoUrl": "https://example.com/$username.jpg"
    };
    _sendMessage(jsonMessage);
  }

  void createRoom(List<String> participants) {
    final jsonMessage = {
      "type": "createRoom",
      "userID": _userID,
      "username": _username,
      "participants": participants
    };
    _sendMessage(jsonMessage);
  }

  void joinRoom(String roomID) {
    final jsonMessage = {
      "type": "joinRoom",
      "userID": _userID,
      "roomID": roomID
    };
    _sendMessage(jsonMessage);
  }

  void leaveRoom(String roomID) {
    final jsonMessage = {
      "type": "leaveRoom",
      "userID": _userID,
      "roomID": roomID
    };
    _sendMessage(jsonMessage);
  }

  void sendTextMessage(String message, String roomID) {
    final jsonMessage = {
      "type": "sendMessage",
      "userID": _userID,
      "messageType": "text",
      "message": message,
      "roomID": roomID
    };
    _sendMessage(jsonMessage);
  }

  void sendImageMessage(String imageUrl, String roomID) {
    final jsonMessage = {
      "type": "sendMessage",
      "userID": _userID,
      "messageType": "image",
      "message": imageUrl,
      "roomID": roomID
    };
    _sendMessage(jsonMessage);
  }

  void _sendMessage(Map<String, dynamic> jsonMessage) {
    if (isConnected) {
      _channel!.sink.add(jsonEncode(jsonMessage));
    } else {
      print(
          'Cannot send message: WebSocket is not connected. Attempting to reconnect...');
      connect();
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
