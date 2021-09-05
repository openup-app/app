import 'package:flutter/material.dart';
import 'package:openup/lobby_page.dart';

const _tempApplicationHost = '192.168.1.118:8080';
const _tempSignalingHost = '192.168.1.118:8081';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meet people'),
      ),
      body: Center(
        child: OutlinedButton.icon(
          label: const Text('Talk to someone new'),
          icon: const Icon(Icons.call),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const LobbyPage(
                    applicationHost: _tempApplicationHost,
                    signalingHost: _tempSignalingHost,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
