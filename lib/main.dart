import 'package:flutter/material.dart';
import 'package:openup/call_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const _tempHost = '192.168.1.118:8080';

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CallPage(host: _tempHost),
    );
  }
}
