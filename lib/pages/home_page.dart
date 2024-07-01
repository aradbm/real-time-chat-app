import 'package:flutter/material.dart';
import 'main_chat_page.dart';
import '../websocket_service.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final WebSocketService websocketService;

  const MyHomePage(
      {super.key, required this.title, required this.websocketService});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String userID = "";
  String username = "";
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showUsernameDialog();
    });
  }

  void _showUsernameDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a username'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => username = value,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                onChanged: (value) => userID = value,
                decoration: const InputDecoration(labelText: 'User ID'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (username.isNotEmpty && userID.isNotEmpty) {
                  Navigator.of(context).pop();
                  _initializeUser();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _initializeUser() {
    setState(() {
      isInitializing = true;
    });
    widget.websocketService.connect().then((_) {
      widget.websocketService.initializeUser(userID, username);
      _navigateToMainChat();
    });
  }

  void _navigateToMainChat() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainChatPage(
          websocketService: widget.websocketService,
          userID: userID,
          username: username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: isInitializing
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _showUsernameDialog,
                child: const Text('Login'),
              ),
      ),
    );
  }
}
