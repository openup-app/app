import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/view_profile_page.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

part 'chat_page.freezed.dart';

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

  bool _showUnreadMessageButton = false;
  bool _fetchingMore = false;

  static const _itemExtent = 66.0;

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
          if (_messages != null) {
            // Add new message and fix the visual list offset
            final atBottom = _scrollController.position.pixels >=
                _scrollController.position.maxScrollExtent;
            setState(() => _messages![message.messageId!] = message);
            if (atBottom) {
              _animateToBottom();
            } else {
              setState(() => _showUnreadMessageButton = true);
            }
          }
        }
      },
      onConnectionError: () {
        // TODO: Deal with connection error
      },
    );

    final profile = ref.read(userProvider).profile!;
    setState(() => _myPhoto = profile.photo);

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
      _otherProfile = chatroom.profile.profile;
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
    final messages = _messages?.values.toList()
      ?..sort(_dateAscendingMessageSorter);
    final items = _messagesToItems(messages ?? []);
    final chatroom = _chatroom;
    return ColoredBox(
      // Background for iOS back gesture
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final topPadding = MediaQuery.of(context).padding.top + 16;
          const appBarHeight = 84.0;
          final listBoxHeight =
              constraints.maxHeight - (topPadding + appBarHeight);
          return Column(
            children: [
              Container(
                height: topPadding,
                color: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
              ),
              Container(
                height: appBarHeight,
                color: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    const BackIconButton(
                      color: Color.fromRGBO(0xBD, 0xBD, 0xBD, 1.0),
                    ),
                    const Spacer(),
                    if (_otherProfile != null) ...[
                      Button(
                        onPressed: () {
                          context.pushNamed(
                            'view_profile',
                            extra: ViewProfilePageArguments.profile(
                              profile: _otherProfile!,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                    left: -6,
                                    top: -34,
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
                              AutoSizeText(
                                _otherProfile?.name ?? '',
                                minFontSize: 16,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      Builder(
                        builder: (context) {
                          final profile = chatroom?.profile;
                          return Button(
                            onPressed: profile == null
                                ? null
                                : () {
                                    SheetControl.of(context).close();
                                    ref.read(discoverProvider.notifier).state =
                                        DiscoverAction.viewProfile(profile);
                                  },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'assets/images/location_search.png',
                                width: 26,
                                height: 25,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
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
                    else if (items.isNotEmpty && chatroom != null) ...[
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: listBoxHeight,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(
                              bottom:
                                  90 + MediaQuery.of(context).padding.bottom),
                          itemExtent: _itemExtent,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return item.when(
                              info: (info) {
                                return SizedBox(
                                  height: _itemExtent,
                                  child: Center(
                                    child: Text(
                                      'Voice Message\n${formatLongDateAndTime(info.date.toLocal())}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        height: 1.5,
                                        color: Color.fromRGBO(
                                            0x8C, 0x8C, 0x8C, 1.0),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              message: (message) {
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
                                    final isPlaying = playbackInfo.state ==
                                        PlaybackState.playing;
                                    return AudioChatMessage(
                                      message: message,
                                      fromMe: fromMe,
                                      photo: (fromMe
                                              ? _myPhoto
                                              : _otherProfile?.photo) ??
                                          '',
                                      playbackInfo: playbackInfo,
                                      height: _itemExtent,
                                      onPressed: () async {
                                        if (isPlaying) {
                                          _audio.stop();
                                          setState(
                                              () => _playbackMessageId = null);
                                        } else {
                                          setState(() => _playbackMessageId =
                                              message.messageId);
                                          await _audio
                                              .setUrl(message.content.url);
                                          if (mounted) {
                                            _audio.play();
                                          }
                                        }
                                      },
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 80 + MediaQuery.of(context).padding.bottom,
                      child: const ColoredBox(
                        color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 16),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: IgnorePointer(
                        ignoring: !_showUnreadMessageButton,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutQuart,
                          opacity: _showUnreadMessageButton ? 1.0 : 0.0,
                          child: _UnreadMessagesButton(
                            onPressed: _animateToBottom,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<RecordingResult?> _showRecordPanel(BuildContext context) async {
    return showModalBottomSheet<RecordingResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return RecordPanelSurface(
          child: RecordPanel(
            onCancel: Navigator.of(context).pop,
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
        setState(() => _messages![pendingId] = r);
        final chatroom = _chatroom;
        if (chatroom != null && chatroom.inviteState == ChatroomState.invited) {
          setState(() {
            _chatroom = chatroom.copyWith(inviteState: ChatroomState.accepted);
            ref
                .read(userProvider2.notifier)
                .acceptChatroom(chatroom.profile.profile.uid);
          });
        }
      },
    );
  }

  void _animateToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      }
    });
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    ref.read(_scrollProvider.notifier).update(offset);
    final messages = _messages;

    if (messages == null) {
      return;
    }

    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        _scrollController.position.extentBefore < 350 &&
        messages.isNotEmpty) {
      var oldest = messages.values.first.date;
      for (final m in messages.values) {
        if (m.date.isBefore(oldest)) {
          oldest = m.date;
        }
      }
      _fetchHistory(startDate: oldest);
    }

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent &&
        _showUnreadMessageButton) {
      setState(() => _showUnreadMessageButton = false);
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
        _otherProfile = r.profile.profile;
      }),
    );
  }

  Future<void> _fetchHistory({DateTime? startDate}) async {
    if (_fetchingMore) {
      return;
    }

    setState(() => _fetchingMore = true);
    final api = ref.read(apiProvider);
    final result = await api.getMessages(
      widget.otherUid,
      startDate: startDate,
    );
    if (!mounted) {
      return;
    }

    setState(() => _fetchingMore = false);

    result.fold(
      (l) => displayError(context, l),
      (messages) {
        final entries = _messages?.entries.toList() ?? [];
        entries.addAll(messages.map((e) => MapEntry(e.messageId!, e)).toList());
        if (entries.isEmpty) {
          return;
        }

        if (_scrollController.hasClients) {
          final tempMessages = Map<String, ChatMessage>.of(_messages ?? {});
          final itemCountBefore =
              _messagesToItems(tempMessages.values.toList()).length;
          final itemCountAfter = _messagesToItems(
                  (tempMessages..addEntries(entries)).values.toList())
              .length;
          final newItemCount = itemCountAfter - itemCountBefore;
          _scrollController.jumpTo(
              _scrollController.position.pixels + newItemCount * _itemExtent);
        }

        setState(() {
          _messages?.clear();
          _messages = (_messages ?? {})..addEntries(entries);
        });
      },
    );
  }

  List<ChatItem> _messagesToItems(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return [];
    }

    final sortedMessages = List.of(messages)..sort(_dateAscendingMessageSorter);
    var date = sortedMessages.last.date;
    final items = sortedMessages.map((e) => ChatItem.message(e)).toList();

    for (var i = items.length - 1; i >= 0; i--) {
      final itemDate = (items[i] as _Message).message.date;
      if (itemDate.year != date.year ||
          itemDate.month != date.month ||
          itemDate.day != date.day) {
        items.insert(i + 1, ChatItem.info(ChatInfo.date(date)));
      }
      date = itemDate;
    }
    items.insert(0, ChatItem.info(ChatInfo.date(date)));

    return items;
  }
}

class _UnreadMessagesButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _UnreadMessagesButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Button(
        onPressed: onPressed,
        child: Container(
          width: 32,
          height: 32,
          margin: const EdgeInsets.all(8.0),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 2),
                blurRadius: 6,
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const RotatedBox(
            quarterTurns: 1,
            child: Icon(
              Icons.chevron_right,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class RecordingResult {
  final Uint8List audio;
  final Duration duration;
  RecordingResult(this.audio, this.duration);
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
        width: 123,
        height: 46,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

int _dateAscendingMessageSorter(ChatMessage a, ChatMessage b) =>
    a.date.compareTo(b.date);

@freezed
class ChatItem with _$ChatItem {
  const factory ChatItem.message(ChatMessage message) = _Message;
  const factory ChatItem.info(ChatInfo info) = _Info;
}

@freezed
class ChatInfo with _$ChatInfo {
  const factory ChatInfo.date(DateTime date) = _Date;
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
