import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/users/profile.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatHost;
  final PublicProfile profile;
  final String chatroomId;

  const ChatScreen({
    Key? key,
    required this.chatHost,
    required this.profile,
    required this.chatroomId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  ChatApi? _chatApi;
  bool _inputBoxVisible = false;
  final _messages = <ChatMessage>[];

  bool _connectionError = false;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    _chatApi = ChatApi(
      host: widget.chatHost,
      uid: uid,
      chatroomId: widget.chatroomId,
      onMessage: (message) {
        setState(() => _messages.insert(0, message));
      },
      onConnectionError: () {
        if (mounted) {
          setState(() => _connectionError = true);
        }
      },
    );
  }

  @override
  void dispose() {
    _chatApi?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text('${message.content} ${message.type}'),
                  subtitle: Text(message.date.toIso8601String()),
                );
              },
            ),
          ),
          Container(
            color: Colors.grey,
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: () {
                    setState(() => _inputBoxVisible = !_inputBoxVisible);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.phone),
                  onPressed: () {
                    setState(() => _inputBoxVisible = !_inputBoxVisible);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.video_call),
                  onPressed: () {
                    setState(() => _inputBoxVisible = !_inputBoxVisible);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () {
                    setState(() => _inputBoxVisible = !_inputBoxVisible);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    setState(() => _inputBoxVisible = !_inputBoxVisible);
                  },
                ),
              ],
            ),
          ),
          if (_inputBoxVisible)
            SizedBox(
              height: 250,
              child: InkWell(
                onTap: () => _chatApi?.sendMessage(ChatType.emoji, 'Test'),
                child: const Center(
                  child: FlutterLogo(size: 100),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatArguments {
  final PublicProfile profile;
  final String chatroomId;

  ChatArguments({
    required this.profile,
    required this.chatroomId,
  });
}
