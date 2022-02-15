import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_input_box.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String host;
  final int webPort;
  final int socketPort;
  final String uid;
  final String chatroomId;

  const ChatScreen({
    Key? key,
    required this.host,
    required this.webPort,
    required this.socketPort,
    required this.uid,
    required this.chatroomId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _kDateFormat = DateFormat('EEEE h:mm');

  ChatApi? _chatApi;
  _InputType _inputType = _InputType.none;

  final _messages = <String, ChatMessage>{};

  final _scrollController = ScrollController();

  bool _connectionError = false;
  late final String _uid;

  bool _loading = true;

  PublicProfile? _profile;
  String? _myAvatar;

  @override
  void initState() {
    super.initState();

    _init();
  }

  void _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user is logged in';
    }
    _uid = user.uid;
    _chatApi = ChatApi(
      host: widget.host,
      webPort: widget.webPort,
      socketPort: widget.socketPort,
      authToken: await user.getIdToken(),
      uid: _uid,
      chatroomId: widget.chatroomId,
      onMessage: (message) {
        setState(() => _messages[message.messageId!] = message);
      },
      onConnectionError: () {
        if (mounted) {
          setState(() => _connectionError = true);
        }
      },
    );

    final usersApi = ref.read(usersApiProvider);
    usersApi.getPublicProfile(_uid).then((profile) {
      if (mounted) {
        setState(() => _myAvatar = profile.photo);
      }
    });

    usersApi.getPublicProfile(widget.uid).then((profile) {
      if (mounted) {
        setState(() => _profile = profile);
      }
    });

    _fetchHistory();

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _chatApi?.dispose();
    _scrollController.removeListener(_scrollListener);
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
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 64,
                            bottom: 80,
                          ),
                          itemCount: _messages.length + (_loading ? 1 : 0),
                          itemBuilder: (context, forwardIndex) {
                            var index =
                                _messages.values.length - forwardIndex - 1;
                            if (_loading && forwardIndex == _messages.length) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final message = _messages.values.toList()[index];
                            final fromMe = message.uid == _uid;

                            const ColorFilter defaultColorMatrix =
                                ColorFilter.matrix(
                              <double>[
                                1, 0, 0, 0, 0, // Comments to stop dart format
                                0, 1, 0, 0, 0, //
                                0, 0, 1, 0, 0, //
                                0, 0, 0, 1, 0, //
                              ],
                            );

                            // Based on Lomski's answer at https://stackoverflow.com/a/62078847/1702627
                            const ColorFilter greyscaleColorMatrix =
                                ColorFilter.matrix(
                              <double>[
                                0.2126, 0.7152, 0.0722, 0,
                                0, // Comments to stop dart format
                                0.2126, 0.7152, 0.0722, 0, 0, //
                                0.2126, 0.7152, 0.0722, 0, 0, //
                                0, 0, 0, 1, 0, //
                              ],
                            );

                            final messageReady = message.messageId != null;

                            return Container(
                              key:
                                  messageReady ? Key(message.messageId!) : null,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              alignment: fromMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: IgnorePointer(
                                ignoring: !messageReady,
                                child: ColorFiltered(
                                  colorFilter: messageReady
                                      ? defaultColorMatrix
                                      : greyscaleColorMatrix,
                                  child: Builder(
                                    builder: (context) {
                                      switch (message.type) {
                                        case ChatType.emoji:
                                          return _buildEmojiMessage(message);
                                        case ChatType.image:
                                          return _buildImageMessage(message);
                                        case ChatType.video:
                                          return VideoChatMessage(
                                            videoUrl: message.content,
                                            date: _buildDateText(message.date),
                                            fromMe: fromMe,
                                          );
                                        case ChatType.audio:
                                          return AudioChatMessage(
                                            audioUrl: message.content,
                                            photoUrl: fromMe
                                                ? _myAvatar
                                                : _profile?.photo ?? '',
                                            date: _buildDateText(message.date),
                                            fromMe: fromMe,
                                          );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (!_loading && _messages.isEmpty)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Send your first message to ${_profile != null ? _profile!.name : ''}',
                              style: Theming.of(context).text.bodySecondary,
                              textAlign: TextAlign.center,
                            ),
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
                          child: Material(
                            type: MaterialType.transparency,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add_a_photo,
                                      color: _inputType == _InputType.imageVideo
                                          ? Theming.of(context).friendBlue3
                                          : null),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return Scaffold(
                                            body: ImageVideoInputBox(
                                              onCapture: (chatType, path) {
                                                _send(chatType, path);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.phone),
                                  onPressed: () {
                                    final profile = _profile;
                                    if (profile != null) {
                                      _call(profile, video: false);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.video_camera_front),
                                  onPressed: () {
                                    final profile = _profile;
                                    if (profile != null) {
                                      _call(profile, video: true);
                                    }
                                  },
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
                            return const SizedBox.shrink();
                          case _InputType.audio:
                            return AudioInputBox(
                              onRecord: (path) => _send(ChatType.audio, path),
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
            Positioned(
              left: 0,
              top: 16 + MediaQuery.of(context).padding.top,
              child: const BackIconButton(),
            ),
            Positioned(
              top: 16 + MediaQuery.of(context).padding.top,
              child: Button(
                onPressed: () {
                  final profile = _profile;
                  if (profile != null) {
                    Navigator.of(context).pushNamed(
                      'public-profile',
                      arguments: PublicProfileArguments(
                        publicProfile: profile,
                        editable: false,
                      ),
                    );
                  }
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
                    _profile?.name ?? '',
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
      style: const TextStyle(
        fontSize: 100,
        color: Colors.white,
      ),
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
                frameBuilder: fadeInFrameBuilder,
                loadingBuilder: circularProgressLoadingBuilder,
                errorBuilder: iconErrorBuilder,
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

  Widget _buildDateText(
    DateTime date, {
    double opacity = 0.5,
  }) {
    return Text(
      _kDateFormat.format(date.toLocal()),
      style: Theming.of(context).text.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.white.withOpacity(opacity)),
    );
  }

  void _send(ChatType type, String content) async {
    const uuid = Uuid();
    final pendingId = uuid.v4();
    setState(() {
      _messages[pendingId] = ChatMessage(
        uid: _uid,
        date: DateTime.now().toUtc(),
        type: type,
        content: content,
      );
    });
    final message =
        await _chatApi?.sendMessage(_uid, widget.chatroomId, type, content);

    if (message == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _messages[pendingId] = message;
      });
    }

    _scrollController.jumpTo(0);
  }

  void _scrollListener() {
    final startDate = _messages.values.first.date;
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _scrollController.position.extentAfter < 200 &&
        _messages.isNotEmpty &&
        !_loading) {
      setState(() => _loading = true);
      _fetchHistory(startDate: startDate);
    }
  }

  void _fetchHistory({DateTime? startDate}) {
    _chatApi
        ?.getMessages(widget.chatroomId, startDate: startDate)
        .then((messages) {
      if (mounted) {
        final entries = _messages.entries.toList();
        entries.insertAll(0, messages.map((e) => MapEntry(e.messageId!, e)));
        setState(() {
          _loading = false;
          _messages.clear();
          _messages.addEntries(entries);
        });
      }
    });
  }

  void _call(
    PublicProfile profile, {
    required bool video,
  }) async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    // TODO: Use correct purpose
    final purpose = Purpose.friends.name;
    final route = video ? '$purpose-video-call' : '$purpose-voice-call';
    final usersApi = ref.read(usersApiProvider);
    final rid = await usersApi.call(_uid, profile.uid, video);
    Navigator.of(context).pushNamed(
      route,
      arguments: CallPageArguments(
        rid: rid,
        profiles: [profile.toSimpleProfile()],
        rekindles: [],
        serious: false,
      ),
    );
  }

  _InputType _switchToInputTypeOrNone(_InputType type) =>
      _inputType == type ? _InputType.none : type;
}

enum _InputType { emoji, imageVideo, audio, none }

class ChatArguments {
  final String uid;
  final String chatroomId;

  ChatArguments({
    required this.uid,
    required this.chatroomId,
  });
}
