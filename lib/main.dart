import 'package:flutter/material.dart';
import 'package:web_socket_test/pages/home_page.dart';
import 'websocket_service.dart';

void main() async {
  final websocketService = WebSocketService();
  await websocketService.connect();
  runApp(MyApp(websocketService: websocketService));
}

class MyApp extends StatelessWidget {
  final WebSocketService websocketService;

  const MyApp({super.key, required this.websocketService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Websocket Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(
          title: 'Websocket Demo', websocketService: websocketService),
    );
  }
}
