import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

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
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/waveforms.dart';
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
    const innerItemSize = 300.0;
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
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: listContentsHeight,
                        maxHeight: listContentsHeight,
                        child: _AcceptRejectBanner(
                          chatroom: _chatroom!,
                          child: ListView.builder(
                            clipBehavior: Clip.none,
                            controller: _scrollController,
                            padding: EdgeInsets.zero,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemExtent: itemHeight,
                            itemCount: messages.length + fakeIndexCount,
                            itemBuilder: (context, fakeIndex) {
                              // Invisible item to shift the first bubble closer
                              if (fakeIndex < fakeIndexCount) {
                                return const IgnorePointer(
                                  child: _PerspectiveBubble(
                                    scrollTop: 0,
                                    listHeight: listContentsHeight,
                                    itemHeight: itemHeight,
                                    itemTopInList: 0,
                                    child: SizedBox.shrink(),
                                  ),
                                );
                              }
                              final index = fakeIndex - fakeIndexCount;
                              final message = messages[index];
                              final myUid = ref.read(userProvider).uid;
                              final fromMe = message.uid == myUid;
                              final isCurrent =
                                  _playbackMessageId == message.messageId;
                              final playbackStream =
                                  isCurrent ? _audio.playbackInfoStream : null;
                              return IgnorePointer(
                                key: ValueKey(message.messageId ?? ''),
                                child: StreamBuilder<PlaybackInfo>(
                                  initialData: const PlaybackInfo(),
                                  stream: playbackStream,
                                  builder: (context, snapshot) {
                                    final playbackInfo = snapshot.requireData;
                                    final isPlaying = playbackInfo.state ==
                                        PlaybackState.playing;
                                    final isLoading = playbackInfo.state ==
                                        PlaybackState.loading;
                                    return _PerspectiveBubble(
                                      scrollTop: ref.watch(_scrollProvider),
                                      listHeight: listContentsHeight,
                                      itemHeight: itemHeight,
                                      itemTopInList: fakeIndex * itemHeight,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: fromMe ? 64.0 : 0.0,
                                            right: fromMe ? 0.0 : 64.0,
                                          ),
                                          child: StreamBuilder<PlaybackInfo>(
                                            initialData: const PlaybackInfo(),
                                            stream: playbackStream ??
                                                Stream.fromIterable(
                                                    [const PlaybackInfo()]),
                                            builder: (context, snapshot) {
                                              final playbackInfo =
                                                  snapshot.requireData;
                                              // Center in large parent to contain blur
                                              return ColoredBox(
                                                color: Colors.transparent,
                                                child: Center(
                                                  child: _ChatMessage(
                                                    photo: fromMe
                                                        ? _myPhoto
                                                        : _otherProfile?.photo,
                                                    fromMe: fromMe,
                                                    message: message,
                                                    height: itemHeight,
                                                    isLoading: isLoading,
                                                    frequenciesColor: isPlaying
                                                        ? const Color.fromRGBO(
                                                            0x00,
                                                            0xff,
                                                            0xef,
                                                            1.0)
                                                        : const Color.fromRGBO(
                                                            0xAF,
                                                            0xAF,
                                                            0xAF,
                                                            1.0),
                                                    frequencies: isPlaying
                                                        ? playbackInfo
                                                            .frequencies
                                                        : message.content
                                                            .waveform.values,
                                                    onPressed: () async {
                                                      if (isPlaying) {
                                                        _audio.stop();
                                                        setState(() =>
                                                            _playbackMessageId =
                                                                null);
                                                      } else {
                                                        setState(() =>
                                                            _playbackMessageId =
                                                                message
                                                                    .messageId);
                                                        await _audio.setUrl(
                                                            message
                                                                .content.url);
                                                        if (mounted) {
                                                          _audio.play();
                                                        }
                                                      }
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _TouchRegion(
                      scrollTop: ref.watch(_scrollProvider),
                      listHeight: listContentsHeight,
                      itemHeight: itemHeight,
                      itemCount: messages.length + fakeIndexCount,
                      debugShowBounds: false,
                      onPressed: (fakeIndex) {
                        final index = fakeIndex - fakeIndexCount;
                        if (index > 0 && index < messages.length) {
                          final message = messages[index];
                          setState(
                              () => _playbackMessageId = message.messageId);
                          _audio.setUrl(message.content.url);
                          _audio.play();
                        }
                      },
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
          child: RecordPanelContents(
            onSubmit: (audio, duration) =>
                Navigator.of(context).pop(RecordingResult(audio, duration)),
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

// ignore: unused_element
class _TestChild extends StatelessWidget {
  const _TestChild({
    super.key,
    required this.innerItemSize,
    required this.fromMe,
    required this.index,
  });

  final double innerItemSize;
  final bool fromMe;
  final int index;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: innerItemSize,
          height: innerItemSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (fromMe
                ? Colors.pink
                : (index == 4 ? Colors.orange : Colors.blue)),
          ),
        ),
      ),
    );
  }
}

Matrix4 _createTransform({
  required double scrollTop,
  required double listHeight,
  required double itemHeight,
  required double itemTopInList,
}) {
  final scrollBottom = scrollTop + listHeight;
  final runwayLength = listHeight + itemHeight;
  final runwayRatio = 1.0 - (scrollBottom - itemTopInList) / runwayLength;
  final invRatio = 1.0 - runwayRatio;
  return Matrix4.identity()
    // Shift scaling origin down as it scrolls up, so items don't fly upwards
    ..translate(0.0, invRatio * 0.6 * itemHeight * invRatio)
    // Scale based on distance on the runway
    ..scale(runwayRatio.clamp(0.0, double.infinity))
    // Center all items in the list
    ..translate(0.0, runwayLength * (0.5 - runwayRatio))
    // Shift the whole thing down
    ..translate(0.0, -runwayLength * 0.2);
}

class _PerspectiveBubble extends ConsumerWidget {
  final double scrollTop;
  final double listHeight;
  final double itemHeight;
  final double itemTopInList;
  final Widget child;

  const _PerspectiveBubble({
    super.key,
    required this.scrollTop,
    required this.listHeight,
    required this.itemHeight,
    required this.itemTopInList,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final scrollTop = ref.watch(_scrollProvider);
        final scrollBottom = scrollTop + listHeight;
        final runwayLength = listHeight + itemHeight;
        final runwayRatio = 1.0 - (scrollBottom - itemTopInList) / runwayLength;
        // final t = Matrix4.identity()
        //   // Shift scaling origin down as it scrolls up, so items don't fly upwards
        //   ..translate(0.0, invRatio * 0.6 * itemHeight * invRatio)
        //   // Scale based on distance on the runway
        //   ..scale(runwayRatio.clamp(0.0, double.infinity))
        //   // Center all items in the list
        //   ..translate(0.0, runwayLength * (0.5 - runwayRatio))
        //   // Shift the whole thing down
        //   ..translate(0.0, runwayLength * 0.1);
        final t = _createTransform(
          scrollTop: ref.watch(_scrollProvider),
          listHeight: listHeight,
          itemHeight: itemHeight,
          itemTopInList: itemTopInList,
        );

        final x = runwayRatio;
        const top = 0.6;
        var y = 1.0;
        y = x < top ? cos(1.5 * (pi / 2) * (1 - x / top)) : y;
        y = y.clamp(0, 1);
        final blur = 100.0 * (1 - y.clamp(0.0, 1.0));
        return Transform(
          transform: t,
          alignment: Alignment.center,
          origin: Offset(0.0, scrollBottom - itemTopInList - runwayLength),
          child: Opacity(
            opacity: y.clamp(0.0, 1.0),
            // Overflow to contain blur
            child: OverflowBox(
              alignment: Alignment.center,
              minWidth: 600,
              minHeight: 600,
              maxWidth: 600,
              maxHeight: 600,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: blur,
                  sigmaY: blur,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class RecordingResult {
  final Uint8List audio;
  final Duration duration;
  RecordingResult(this.audio, this.duration);
}

class _ChatMessage extends StatelessWidget {
  final String? photo;
  final bool fromMe;
  final ChatMessage message;
  final double height;
  final Color frequenciesColor;
  final bool isLoading;
  final List<double>? frequencies;
  final VoidCallback onPressed;

  const _ChatMessage({
    super.key,
    required this.fromMe,
    required this.photo,
    required this.message,
    required this.height,
    this.isLoading = false,
    required this.frequenciesColor,
    required this.frequencies,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: height,
        height: height,
        child: Button(
          onPressed: message.messageId == null ? null : onPressed,
          useFadeWheNoPressedCallback: false,
          child: _BubbleContainer(
            fromMe: fromMe,
            childBottomLeft:
                fromMe ? _buildSentIndicator(context) : _buildPhoto(),
            childBottomRight: fromMe ? _buildPhoto() : null,
            child: Stack(
              children: [
                if (isLoading)
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 4,
                    child: LoadingIndicator(
                      size: 24,
                      color: frequenciesColor,
                    ),
                  ),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: CustomPaint(
                      size: const Size.fromHeight(140),
                      painter: FrequenciesPainter(
                        frequencies: frequencies ??
                            message.content.waveform.values
                                .map((e) => e.toDouble())
                                .toList(),
                        barCount: 30,
                        color: frequenciesColor,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      formatDuration(message.content.duration),
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 13,
                          color: const Color.fromRGBO(0xFF, 0xF3, 0xF3, 0.8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSentIndicator(BuildContext context) {
    final hasSent = message.messageId != null;
    if (!hasSent) {
      return null;
    }
    return Row(
      children: [
        if (hasSent)
          Text(
            'sent',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: const Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
                fontSize: 16,
                fontWeight: FontWeight.w300),
          ),
        const SizedBox(width: 2),
        const Icon(
          Icons.done,
          size: 16,
          color: Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
        ),
      ],
    );
  }

  Widget _buildPhoto() {
    return Container(
      width: 33,
      height: 33,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: photo == null
          ? null
          : Image.network(
              photo!,
              fit: BoxFit.cover,
            ),
    );
  }
}

class _BlurListItem extends StatefulWidget {
  final ScrollController controller;
  final Widget child;

  const _BlurListItem({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<_BlurListItem> createState() => _BlurListItemState();
}

class _BlurListItemState extends State<_BlurListItem> {
  double _scrollFraction = 1.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    setState(() {
      _scrollFraction = widget.controller.position.pixels /
          widget.controller.position.viewportDimension;
    });

    // final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    // final listItemBox = listItemContext.findRenderObject() as RenderBox;
    // final listItemOffset = listItemBox.localToGlobal(
    //   listItemBox.size.centerLeft(Offset.zero),
    //   ancestor: scrollableBox,
    // );

    // final viewportDimension = scrollable.position.viewportDimension;
    // _scrollFraction = scrollable.position.pixels / viewportDimension;
    // (listItemOffset.dy / viewportDimension); //.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final sigma = _scrollFraction * _scrollFraction * 10.0;
    return ImageFiltered(
      enabled: false,
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: widget.child,
    );
  }
}

class _BubbleContainer extends StatelessWidget {
  final bool fromMe;
  final Widget? childBottomLeft;
  final Widget? childBottomRight;
  final Widget child;

  const _BubbleContainer({
    super.key,
    required this.fromMe,
    this.childBottomLeft,
    this.childBottomRight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: fromMe
                  ? const [
                      Color.fromRGBO(0x6B, 0x00, 0x00, 0.42),
                      Color.fromRGBO(0xF3, 0x0B, 0x0B, 0.8),
                      Color.fromRGBO(0xF3, 0x0B, 0x0B, 0.8),
                    ]
                  : const [
                      Color.fromRGBO(0x00, 0x72, 0x64, 0.53),
                      Color.fromRGBO(0x00, 0x60, 0x6D, 1.0),
                      Color.fromRGBO(0x00, 0x8B, 0x9E, 1.0),
                    ],
              stops: const [0.0, 0.7, 1.0],
            ),
            shape: BoxShape.circle,
          ),
          child: child,
        ),
        if (childBottomLeft != null)
          Align(
            alignment: Alignment.bottomLeft,
            child: childBottomLeft,
          ),
        if (childBottomRight != null)
          Align(
            alignment: Alignment.bottomRight,
            child: childBottomRight,
          ),
      ],
    );
  }
}

class _TouchRegion extends ConsumerWidget {
  final double scrollTop;
  final double listHeight;
  final double itemHeight;
  final int itemCount;
  final bool debugShowBounds;
  final void Function(int index) onPressed;

  const _TouchRegion({
    super.key,
    required this.scrollTop,
    required this.listHeight,
    required this.itemHeight,
    required this.itemCount,
    this.debugShowBounds = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: listHeight,
      child: Consumer(
        builder: (context, ref, child) {
          final maxOnScreenItemCount = (listHeight / itemHeight).ceil() + 1;
          final topItemIndex = (scrollTop ~/ itemHeight).clamp(0, itemCount);
          final bottomItemIndex =
              (topItemIndex + maxOnScreenItemCount).clamp(0, itemCount);
          final topItemStart =
              (scrollTop ~/ itemHeight) * itemHeight - scrollTop;
          final scrollBottom = scrollTop + listHeight;
          final runwayLength = listHeight + itemHeight;
          return Stack(
            children: [
              for (var i = 0; topItemIndex + i < bottomItemIndex; i++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: topItemStart + i * itemHeight,
                  height: itemHeight,
                  child: Builder(
                    builder: (context) {
                      final index = topItemIndex + i;
                      final itemTopInList = index * itemHeight;
                      return Transform(
                        transform: _createTransform(
                          scrollTop: scrollTop,
                          listHeight: listHeight,
                          itemHeight: itemHeight,
                          itemTopInList: itemTopInList,
                        ),
                        alignment: Alignment.center,
                        origin: Offset(
                          0.0,
                          scrollBottom - itemTopInList - runwayLength,
                        ),
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => onPressed(index),
                          child: IgnorePointer(
                            child: Container(
                              height: itemHeight,
                              decoration: BoxDecoration(
                                color: debugShowBounds
                                    ? Colors.blue.withOpacity(0.6)
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
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
