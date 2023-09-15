import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/animation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

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

class _ChatScreenState extends ConsumerState<ChatPage> {
  late final ChatApi _chatApi;
  Chatroom? _chatroom;
  Map<String, ChatMessage>? _messages;
  late final PageController _pageController;

  Profile? _otherProfile;
  final _audio = JustAudioAudioPlayer();
  String? _playbackMessageId;

  bool _showUnreadMessageButton = false;
  bool _fetchingMore = false;

  double _pageScroll = 0;

  // Saves the profile/uid here in case the user gets signed out during chat
  late Profile myProfile;
  late String myUid;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(viewportFraction: 0.7);
    _pageController.addListener(() {
      setState(() => _pageScroll = _pageController.page ?? 0);
    });

    final userState = ref.read(userProvider2);
    myProfile = userState.map(
      guest: (_) => throw 'User is not signed in',
      signedIn: (signedIn) => signedIn.account.profile,
    );
    myUid = myProfile.uid;

    _chatApi = ChatApi(
      host: widget.host,
      socketPort: widget.socketPort,
      uid: myUid,
      otherUid: widget.otherUid,
      onMessage: (message) {
        if (mounted) {
          if (_messages != null) {
            // Add new message and fix the visual list offset
            final atLatest = _pageController.position.pixels >=
                _pageController.position.minScrollExtent;
            setState(() => _messages![message.messageId!] = message);
            if (atLatest) {
              _animateToLatest();
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

    _fetchHistory();

    _chatroom = widget.chatroom;
    final chatroom = widget.chatroom;
    if (chatroom != null) {
      _otherProfile = chatroom.profile.profile;
    } else {
      _fetchChatroom(widget.otherUid);
    }

    _pageController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _chatApi.dispose();
    _audio.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages?.values.toList()
      ?..sort(_dateAscendingMessageSorter);
    final items = _messagesToItems(messages ?? [])
      ..removeWhere((i) => i is _Info);
    final chatroom = _chatroom;

    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          SizedBox(
            height: 84.0,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: Button(
                      onPressed: Navigator.of(context).pop,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: RotatedBox(
                          quarterTurns: 2,
                          child: SvgPicture.asset(
                            'assets/images/chevron_right.svg',
                            colorFilter: const ColorFilter.mode(
                              Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0),
                              BlendMode.srcIn,
                            ),
                            height: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_otherProfile != null) ...[
                  Center(
                    child: Button(
                      onPressed: () {
                        _audio.pause();
                        showProfileBottomSheet(
                          context: context,
                          profile: _otherProfile!,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
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
                            const SizedBox(width: 8),
                            OnlineIndicatorBuilder(
                              uid: _otherProfile!.uid,
                              builder: (context, online) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (online) const SizedBox(height: 12),
                                    AutoSizeText(
                                      _otherProfile?.name ?? '',
                                      minFontSize: 16,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Covered By Your Grace',
                                        fontSize: 24,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (online)
                                      const Text(
                                        'online',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color.fromRGBO(
                                              0x94, 0x94, 0x94, 1.0),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (messages == null)
                  Padding(
                    padding: EdgeInsets.only(
                        bottom:
                            (80 + MediaQuery.of(context).padding.bottom) / 2),
                    child: const Center(
                      child: LoadingIndicator(),
                    ),
                  ),
                if (messages != null &&
                    messages.isEmpty &&
                    _otherProfile != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Send your first message to ${_otherProfile!.name}',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromRGBO(0x70, 0x70, 0x70, 1.0)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else if (items.isNotEmpty && chatroom != null) ...[
                  Center(
                    child: SizedBox(
                      height: 354,
                      child: PageView.builder(
                        controller: _pageController,
                        reverse: true,
                        itemCount: items.length,
                        clipBehavior: Clip.none,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final scrollOffset =
                              (index - _pageScroll).abs().clamp(0, 1);
                          return item.when(
                            info: (info) => const SizedBox.shrink(),
                            message: (message) {
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
                              return Transform.scale(
                                alignment: Alignment.center,
                                scale: 1 - scrollOffset * 0.1,
                                child: WiggleBuilder(
                                  enabled: scrollOffset < 1,
                                  seed: message.messageId.hashCode,
                                  builder: (context, child, wiggle) {
                                    final attenuation = 1.0 - scrollOffset;
                                    final offset = Offset(
                                          wiggle(frequency: 0.3, amplitude: 20),
                                          wiggle(frequency: 0.3, amplitude: 20),
                                        ) *
                                        attenuation;

                                    final rotationZ = wiggle(
                                        frequency: 0.5,
                                        amplitude: radians(4) * attenuation);
                                    final rotationY = wiggle(
                                        frequency: 0.5,
                                        amplitude: radians(10) * attenuation);
                                    const perspectiveDivide = 0.002;
                                    final transform = Matrix4.identity()
                                      ..setEntry(3, 2, perspectiveDivide)
                                      ..rotateY(rotationY)
                                      ..rotateZ(rotationZ);
                                    return Transform.translate(
                                      offset: offset,
                                      child: Transform(
                                        transform: transform,
                                        alignment: Alignment.center,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      Color.fromRGBO(
                                          0x00,
                                          0x00,
                                          0x00,
                                          (index - _pageScroll)
                                                  .abs()
                                                  .clamp(0, 1) *
                                              0.6),
                                      BlendMode.srcOver,
                                    ),
                                    child: StreamBuilder<bool>(
                                      stream: playbackStream.map((event) =>
                                          event.state == PlaybackState.playing),
                                      initialData: false,
                                      builder: (context, snapshot) {
                                        final isPlaying = snapshot.requireData;
                                        return Button(
                                          onPressed: () =>
                                              _playPause(message, isPlaying),
                                          child: Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(5)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                AspectRatio(
                                                  aspectRatio: 1 / 1,
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Image.network(
                                                        fromMe
                                                            ? myProfile.photo
                                                            : chatroom.profile
                                                                .profile.photo,
                                                        fit: BoxFit.cover,
                                                      ),
                                                      if (!isPlaying)
                                                        const Icon(
                                                          Icons.play_arrow,
                                                          size: 64,
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 8,
                                                              color: Color
                                                                  .fromRGBO(
                                                                      0x00,
                                                                      0x00,
                                                                      0x00,
                                                                      0.25),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        formatDate(message.date
                                                            .toLocal()),
                                                        style: const TextStyle(
                                                          fontFamily:
                                                              'Covered By Your Grace',
                                                          fontSize: 22,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Color.fromRGBO(
                                                              0x29,
                                                              0x29,
                                                              0x29,
                                                              1.0),
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      formatTime(message.date
                                                          .toLocal()),
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'Covered By Your Grace',
                                                        fontSize: 22,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Color.fromRGBO(
                                                            0x29,
                                                            0x29,
                                                            0x29,
                                                            1.0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 14),
                                                StreamBuilder<PlaybackInfo>(
                                                  key: ValueKey(
                                                      message.messageId ?? ''),
                                                  initialData:
                                                      const PlaybackInfo(),
                                                  stream: playbackStream,
                                                  builder: (context, snapshot) {
                                                    final playbackInfo =
                                                        snapshot.requireData;
                                                    return AudioMessagePlaybackBar(
                                                      message: message,
                                                      playbackInfo:
                                                          playbackInfo,
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 12),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: IgnorePointer(
                    ignoring: !_showUnreadMessageButton,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutQuart,
                      opacity: _showUnreadMessageButton ? 1.0 : 0.0,
                      child: _UnreadMessagesButton(
                        onPressed: _animateToLatest,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _playPause(ChatMessage message, bool isPlaying) async {
    if (isPlaying) {
      _audio.pause();
    } else {
      if (_playbackMessageId == message.messageId) {
        _audio.play();
      } else {
        setState(() => _playbackMessageId = message.messageId);

        // Play locally or from network
        if (message.messageId == null) {
          await _audio.setPath(message.content.url);
        } else {
          await _audio.setUrl(message.content.url);
        }
        if (mounted) {
          _audio.play();
        }
      }
    }
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
    setState(() {
      _messages![pendingId] = ChatMessage(
        uid: myUid,
        date: DateTime.now().toUtc(),
        reactions: {},
        content: MessageContent.audio(
          type: ChatType.audio,
          url: file.path,
          duration: duration,
        ),
      );
    });

    if (mounted) {
      _animateToLatest();
    }

    final api = ref.read(apiProvider);
    final result = await api.sendMessage(
      widget.otherUid,
      ChatType.audio,
      file.path,
    );

    ref.read(analyticsProvider).trackSendMessage();

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

  void _animateToLatest() {
    if (_pageController.hasClients) {
      _pageController.animateTo(
        _pageController.position.minScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    }
  }

  void _scrollListener() {
    final offset = _pageController.offset;
    ref.read(_scrollProvider.notifier).update(offset);
    final messages = _messages;

    if (messages == null) {
      return;
    }

    if (_pageController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _pageController.position.extentAfter < 350 &&
        messages.isNotEmpty) {
      var oldest = messages.values.first.date;
      for (final m in messages.values) {
        if (m.date.isBefore(oldest)) {
          oldest = m.date;
        }
      }
      _fetchHistory(startDate: oldest);
    }

    if (_pageController.position.pixels >=
            _pageController.position.maxScrollExtent &&
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

    return items.reversed.toList();
  }

  void _showLocation(DiscoverProfile profile) {
    SheetControl.of(context).close();
    ref.read(discoverActionProvider.notifier).state =
        DiscoverAction.viewProfile(profile);
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
          color: Color.fromRGBO(0x1E, 0x79, 0xF8, 1.0),
          borderRadius: BorderRadius.all(Radius.circular(25)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _LocationOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  const _LocationOverlay({
    super.key,
    required this.onComplete,
  });

  @override
  State<_LocationOverlay> createState() => _LocationOverlayState();
}

class _LocationOverlayState extends State<_LocationOverlay> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 261,
      height: 218,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        color: const Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/images/location_off.svg',
            height: 42,
          ),
          const SizedBox(height: 32),
          const Text(
            'Location Currently\nDisabled',
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.3,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white,
            ),
          ),
        ],
      ),
    )
        .animate(onComplete: (_) => widget.onComplete())
        .fadeIn(
          curve: Curves.easeOutQuart,
          duration: const Duration(milliseconds: 1500),
        )
        .fadeOut(
          delay: const Duration(milliseconds: 1200),
          duration: const Duration(milliseconds: 1500),
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
