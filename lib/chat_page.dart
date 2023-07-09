import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final _scrollProvider =
    StateNotifierProvider<_ScrollNotifier, double>((ref) => _ScrollNotifier());

class ChatPage extends ConsumerStatefulWidget {
  final String host;
  final int webPort;
  final int socketPort;
  final String otherUid;
  final Chatroom? chatroom;
  final DateTime? endTime;

  const ChatPage({
    Key? key,
    required this.host,
    required this.webPort,
    required this.socketPort,
    required this.otherUid,
    this.chatroom,
    this.endTime,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  late final ChatApi _chatApi;
  Chatroom? _chatroom;
  Map<String, ChatMessage>? _messages;
  final _scrollController = ScrollController();

  Profile? _otherProfile;
  String? _myPhoto;

  final _audio = JustAudioAudioPlayer();
  String? _playbackMessageId;

  @override
  void initState() {
    super.initState();

    _chatApi = ChatApi(
      host: widget.host,
      socketPort: widget.socketPort,
      uid: ref.read(userProvider).uid,
      otherUid: widget.otherUid,
      onMessage: (message) {
        if (mounted) {
          if (_messages == null) {
            setState(() => _messages![message.messageId!] = message);
          }
        }
      },
      onConnectionError: () {
        // TODO: Deal with connection error
      },
    );

    final profile = ref.read(userProvider).profile!;
    setState(() => _myPhoto = profile.collection.photos.first.url);

    _fetchHistory().then((value) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted && _scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });

    _chatroom = widget.chatroom;
    final chatroom = widget.chatroom;
    if (chatroom != null) {
      _otherProfile = chatroom.profile;
    } else {
      _fetchChatroom(widget.otherUid);
    }

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _chatApi.dispose();
    _audio.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const innerItemSize = 250.0;
    const itemHeight = innerItemSize + 16;
    final messagesMap = _messages;
    final messages = messagesMap?.values.toList();
    final chatroom = _chatroom;
    return LayoutBuilder(
      builder: (context, constraints) {
        const dragHandleGap = 24.0;
        const appBarHeight = 67.0;
        const bottomButtonHeight = 51.0 + 16 * 2;
        final listBoxHeight = constraints.maxHeight -
            (MediaQuery.of(context).padding.top + dragHandleGap + appBarHeight);
        const onScreenItemCount = 4;
        const listContentsHeight = itemHeight * onScreenItemCount;
        const fakeIndexCount = onScreenItemCount - 1;
        return Column(
          children: [
            SizedBox(
              height: dragHandleGap + MediaQuery.of(context).padding.top,
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    bottom: 4.0,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: appBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const BackIconButton(),
                  const Spacer(),
                  if (_otherProfile != null) ...[
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 51,
                              height: 51,
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: _otherProfile?.photo == null
                                  ? const SizedBox.shrink()
                                  : Image.network(
                                      _otherProfile!.photo,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              left: 8,
                              top: -30,
                              width: 78,
                              height: 78,
                              child: OnlineIndicatorBuilder(
                                uid: _otherProfile!.uid,
                                builder: (context, online) {
                                  return online
                                      ? const OnlineIndicator()
                                      : const SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _otherProfile?.name ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ReportBlockPopupMenu2(
                      uid: _otherProfile!.uid,
                      name: _otherProfile!.name,
                      onBlock: Navigator.of(context).pop,
                      builder: (context) {
                        return const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.more_horiz,
                            color: Color.fromRGBO(0x7D, 0x7D, 0x7D, 1.0),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(
              height: listBoxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (messages != null &&
                      messages.isEmpty &&
                      _otherProfile != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: listBoxHeight,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Send your first message to ${_otherProfile!.name}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: const Color.fromRGBO(
                                        0x70, 0x70, 0x70, 1.0)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  else if (messages != null && chatroom != null) ...[
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: listBoxHeight,
                      child: _AcceptRejectBanner(
                        chatroom: _chatroom!,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            final myUid = ref.read(userProvider).uid;
                            final fromMe = message.uid == myUid;
                            final isCurrent =
                                _playbackMessageId == message.messageId;
                            final playbackStream = isCurrent
                                ? _audio.playbackInfoStream
                                : Stream.fromIterable([
                                    PlaybackInfo(
                                      position: Duration.zero,
                                      duration: message.content.duration,
                                      state: PlaybackState.idle,
                                      frequencies: [],
                                    )
                                  ]);
                            return StreamBuilder<PlaybackInfo>(
                              key: ValueKey(message.messageId ?? ''),
                              initialData: const PlaybackInfo(),
                              stream: playbackStream,
                              builder: (context, snapshot) {
                                final playbackInfo = snapshot.requireData;
                                final isPlaying =
                                    playbackInfo.state == PlaybackState.playing;
                                return AudioChatMessage(
                                  message: message,
                                  fromMe: fromMe,
                                  photo: (fromMe
                                          ? _myPhoto
                                          : _otherProfile?.photo) ??
                                      '',
                                  playbackInfo: playbackInfo,
                                  onPressed: () async {
                                    if (isPlaying) {
                                      _audio.stop();
                                      setState(() => _playbackMessageId = null);
                                    } else {
                                      setState(() => _playbackMessageId =
                                          message.messageId);
                                      await _audio.setUrl(message.content.url);
                                      if (mounted) {
                                        _audio.play();
                                      }
                                    }
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: bottomButtonHeight,
                          child: Center(
                            child: _RecordButton(
                              onPressed: () async {
                                _audio.stop();
                                final result = await _showRecordPanel(context);
                                if (result != null && mounted) {
                                  _submit(result.audio, result.duration);
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).padding.bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<RecordingResult?> _showRecordPanel(BuildContext context) async {
    return showModalBottomSheet<RecordingResult>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanel(
            onSubmit: (audio, duration) {
              Navigator.of(context).pop(RecordingResult(audio, duration));
              return Future.value(true);
            },
          ),
        );
      },
    );
  }

  Future<void> _submit(Uint8List audio, Duration duration) async {
    final tempDir = await getTemporaryDirectory();
    final file = await File(path.join(
            tempDir.path, 'chats', '${DateTime.now().toIso8601String()}.m4a'))
        .create(recursive: true);
    await file.writeAsBytes(audio);

    if (!mounted) {
      return;
    }

    const uuid = Uuid();
    final pendingId = uuid.v4();
    final uid = ref.read(userProvider).uid;
    setState(() {
      _messages![pendingId] = ChatMessage(
        uid: uid,
        date: DateTime.now().toUtc(),
        reactions: {},
        content: MessageContent.audio(
          type: ChatType.audio,
          url: file.path,
          duration: duration,
          waveform: const AudioMessageWaveform(
            values: [],
          ),
        ),
      );
    });

    if (mounted && _scrollController.hasClients) {
      _animateToBottom();
    }

    final api = ref.read(apiProvider);
    final result = await api.sendMessage(
      widget.otherUid,
      ChatType.audio,
      file.path,
    );

    ref.read(mixpanelProvider).track("send_message");

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        final chatroom = _chatroom;
        if (chatroom != null && chatroom.inviteState == ChatroomState.invited) {
          setState(() {
            _chatroom = chatroom.copyWith(inviteState: ChatroomState.accepted);
            ref
                .read(userProvider2.notifier)
                .acceptChatroom(chatroom.profile.uid);
          });
          _messages![pendingId] = r;
        }
      },
    );
  }

  void _animateToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    ref.read(_scrollProvider.notifier).update(offset);
    final messages = _messages;

    if (messages == null) {
      return;
    }

    final startDate = messages.values.first.date;
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        _scrollController.position.extentBefore < 400 &&
        messages.isNotEmpty) {
      _fetchHistory(startDate: startDate);
    }
  }

  Future<void> _fetchChatroom(String otherUid) async {
    final api = ref.read(apiProvider);
    final result = await api.getChatroom(widget.otherUid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => setState(() {
        _chatroom = r;
        _otherProfile = r.profile;
      }),
    );
  }

  Future<void> _fetchHistory({DateTime? startDate}) async {
    final api = ref.read(apiProvider);
    final result = await api.getMessages(
      widget.otherUid,
      startDate: startDate,
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (messages) {
        final entries = _messages?.entries.toList() ?? [];
        setState(() {
          entries
              .addAll(messages.map((e) => MapEntry(e.messageId!, e)).toList());
          _messages?.clear();
          _messages = (_messages ?? {})..addEntries(entries);
        });
      },
    );
  }
}

class RecordingResult {
  final Uint8List audio;
  final Duration duration;
  RecordingResult(this.audio, this.duration);
}

class _AcceptRejectBanner extends StatelessWidget {
  final Chatroom chatroom;
  final Widget child;

  const _AcceptRejectBanner({
    super.key,
    required this.chatroom,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: child,
        ),
        if (chatroom.inviteState == ChatroomState.invited)
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(12),
                ),
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              ),
              child: Text(
                'If you send a message to ${chatroom.profile.name}, it will begin your conversation and they will be at the top of your inbox.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    this.label = 'send message',
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 146,
        height: 51,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0xF3, 0x49, 0x50, 1.0),
              Color.fromRGBO(0xDF, 0x39, 0x3F, 1.0),
            ],
          ),
          borderRadius: BorderRadius.all(Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 4),
              blurRadius: 12,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white),
        ),
      ),
    );
  }
}

class _ScrollNotifier extends StateNotifier<double> {
  _ScrollNotifier() : super(0.0);

  void update(double offset) => state = offset;
}

class ChatPageArguments {
  final Chatroom chatroom;

  const ChatPageArguments({
    required this.chatroom,
  });
}

enum CallProfileAction { call, block, report }
