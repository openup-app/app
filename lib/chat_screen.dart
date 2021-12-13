import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_input_box.dart';
import 'package:openup/widgets/theming.dart';

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
  final _kDateFormat = DateFormat('EEEE h:mm');

  ChatApi? _chatApi;
  _InputType _inputType = _InputType.none;
  final _messages = <ChatMessage>[];

  final _scrollController = ScrollController();

  bool _connectionError = false;
  late final String _uid;

  @override
  void initState() {
    super.initState();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }
    _uid = uid;

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
    return WillPopScope(
      onWillPop: () {
        if (_inputType == _InputType.none) {
          return Future.value(true);
        }
        setState(() => _inputType = _InputType.none);
        return Future.value(false);
      },
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0x25, 0x1A, 0x1A, 1.0),
              Color.fromRGBO(0x0C, 0x0C, 0x0C, 1.0),
            ],
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Scrollbar(
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.only(bottom: 72),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final fromMe = message.uid == _uid;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              alignment: fromMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Builder(
                                builder: (context) {
                                  switch (message.type) {
                                    case ChatType.emoji:
                                      return _buildEmojiMessage(message);
                                    case ChatType.image:
                                      return _buildImageMessage(message);
                                    case ChatType.video:
                                      return _buildVideoMessage(message);
                                    case ChatType.audio:
                                      return _buildAudioMessage(
                                        message,
                                        fromMe: fromMe,
                                      );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        height: 64,
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0x42, 0x42, 0x42, 1.0),
                            border: Border.all(
                              color:
                                  const Color.fromRGBO(0x60, 0x5E, 0x5E, 1.0),
                              width: 2,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(36),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.add_a_photo,
                                    color: _inputType == _InputType.imageVideo
                                        ? Theming.of(context).friendBlue3
                                        : null),
                                onPressed: () {
                                  setState(() => _inputType =
                                      _switchToInputTypeOrNone(
                                          _InputType.imageVideo));
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.video_camera_front),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: Icon(Icons.emoji_emotions,
                                    color: _inputType == _InputType.emoji
                                        ? Theming.of(context).friendBlue3
                                        : null),
                                onPressed: () {
                                  setState(() => _inputType =
                                      _switchToInputTypeOrNone(
                                          _InputType.emoji));
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.settings_voice,
                                    color: _inputType == _InputType.audio
                                        ? Theming.of(context).friendBlue3
                                        : null),
                                onPressed: () {
                                  setState(() => _inputType =
                                      _switchToInputTypeOrNone(
                                          _InputType.audio));
                                },
                              ),
                            ],
                          ),
                        ),
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
                          case _InputType.imageVideo:
                            return Center(
                              child: Text(
                                'Image',
                                style: Theming.of(context).text.body,
                              ),
                            );
                          case _InputType.audio:
                            return Center(
                              child: Text(
                                'Audio',
                                style: Theming.of(context).text.body,
                              ),
                            );
                          case _InputType.none:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              left: 8,
              top: 24,
              child: BackButton(),
            ),
            Positioned(
              top: 32,
              child: Button(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    'public-profile',
                    arguments: PublicProfileArguments(
                      publicProfile: widget.profile,
                      editable: false,
                    ),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0x42, 0x42, 0x42, 1.0),
                    border: Border.all(
                      color: const Color.fromRGBO(0x60, 0x5E, 0x5E, 1.0),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(36),
                    ),
                  ),
                  child: Text(
                    widget.profile.name,
                    style: Theming.of(context).text.body,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiMessage(ChatMessage message) {
    return Text(
      message.content,
      style: const TextStyle(fontSize: 100),
    );
  }

  Widget _buildImageMessage(ChatMessage message) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color.fromRGBO(0x9E, 0x9E, 0x9E, 1.0),
          width: 2,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(36),
        ),
      ),
      child: SizedBox(
        width: 200,
        height: 250,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(
                Radius.circular(34),
              ),
              child: Image.network(
                message.content,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 12,
              child: _buildDateText(message.date, opacity: 0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoMessage(ChatMessage message) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(
        Radius.circular(36),
      ),
      child: Button(
        onPressed: () {},
        child: SizedBox(
          width: 200,
          height: 250,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(34),
                ),
                child: Image.network(
                  'https://i.pravatar.cc/250',
                  fit: BoxFit.cover,
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10,
                  sigmaY: 10,
                ),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.3),
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 12,
                child: _buildDateText(message.date, opacity: 0.8),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color.fromRGBO(0x9E, 0x9E, 0x9E, 1.0),
                    width: 2,
                  ),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(36),
                  ),
                ),
                child: const SizedBox.expand(),
              ),
              const Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 48,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage(
    ChatMessage message, {
    required bool fromMe,
  }) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: fromMe
            ? const Color.fromRGBO(0x5E, 0x5C, 0x5C, 0.3)
            : const Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.30),
        border: Border.all(
          color: const Color.fromRGBO(0x60, 0x5E, 0x5E, 1.0),
          width: 2,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(36),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!fromMe)
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Image.network('https://i.pravatar.cc/100'),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: Icon(
              Icons.play_arrow,
              size: 40,
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 100,
                    height: 2,
                    color: Colors.red,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      '00:21',
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontWeight: FontWeight.normal),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: fromMe ? 0 : 8,
                child: Padding(
                  padding: const EdgeInsets.only(top: 40.0, right: 4.0),
                  child: _buildDateText(message.date),
                ),
              ),
            ],
          ),
          if (fromMe)
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Image.network('https://i.pravatar.cc/100'),
            ),
        ],
      ),
    );
  }

  void _send(ChatType type, String content) {
    _chatApi?.sendMessage(type, content);
    _scrollController.jumpTo(0);
  }

  Widget _buildDateText(
    DateTime date, {
    double opacity = 0.5,
  }) {
    return Text(
      _kDateFormat.format(date),
      style: Theming.of(context).text.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white.withOpacity(opacity)),
    );
  }

  _InputType _switchToInputTypeOrNone(_InputType type) =>
      _inputType == type ? _InputType.none : type;
}

enum _InputType { emoji, imageVideo, audio, none }

class ChatArguments {
  final PublicProfile profile;
  final String chatroomId;

  ChatArguments({
    required this.profile,
    required this.chatroomId,
  });
}
