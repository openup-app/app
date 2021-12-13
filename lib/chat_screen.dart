import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/chat_input_box.dart';

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
  _InputType _inputType = _InputType.none;
  final _messages = <ChatMessage>[];
  final _scrollController = ScrollController();

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
      body: WillPopScope(
        onWillPop: () {
          if (_inputType == _InputType.none) {
            return Future.value(true);
          }
          setState(() => _inputType = _InputType.none);
          return Future.value(false);
        },
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                child: ListView.builder(
                  controller: _scrollController,
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
                      setState(() => _inputType =
                          _switchToInputTypeOrNone(_InputType.image));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.phone),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.video_call),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions),
                    onPressed: () {
                      setState(() => _inputType =
                          _switchToInputTypeOrNone(_InputType.emoji));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      setState(() => _inputType =
                          _switchToInputTypeOrNone(_InputType.audio));
                    },
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: SizedBox(
                width: double.infinity,
                height: _inputType == _InputType.none ? 0 : 300,
                child: Builder(
                  builder: (context) {
                    switch (_inputType) {
                      case _InputType.emoji:
                        return EmojiInputBox(
                          onEmoji: (emoji) => _send(ChatType.emoji, emoji),
                        );
                      case _InputType.image:
                        return const SizedBox.shrink();
                      case _InputType.audio:
                        return const SizedBox.shrink();
                      case _InputType.none:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(ChatType type, String content) {
    _chatApi?.sendMessage(type, content);
    _scrollController.jumpTo(0);
  }

  _InputType _switchToInputTypeOrNone(_InputType type) =>
      _inputType == type ? _InputType.none : type;
}

enum _InputType { emoji, image, audio, none }

class ChatArguments {
  final PublicProfile profile;
  final String chatroomId;

  ChatArguments({
    required this.profile,
    required this.chatroomId,
  });
}
