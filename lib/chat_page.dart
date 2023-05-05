import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_view.dart';
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
  final Profile? otherProfile;
  final DateTime? endTime;

  const ChatPage({
    Key? key,
    required this.host,
    required this.webPort,
    required this.socketPort,
    required this.otherUid,
    this.otherProfile,
    this.endTime,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  late final ChatApi _chatApi;
  final _messages = <String, ChatMessage>{};
  final _scrollController = ScrollController();
  bool _loading = true;

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
          setState(() => _messages[message.messageId!] = message);
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
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (mounted && _scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });

    if (widget.otherProfile != null) {
      _otherProfile = widget.otherProfile;
    } else {
      _fetchOtherProfile();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const dragHandleGap = 24.0;
        const appBarHeight = 67.0;
        const bottomButtonHeight = 51.0 + 16 * 2;
        final listHeight = constraints.maxHeight -
            (MediaQuery.of(context).padding.top +
                dragHandleGap +
                appBarHeight +
                bottomButtonHeight +
                MediaQuery.of(context).padding.bottom);
        return Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            const SizedBox(height: dragHandleGap),
            SizedBox(
              height: appBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const BackIconButton(),
                  const Spacer(),
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
                                    widget.otherProfile!.photo,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          if (_otherProfile != null)
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
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromRGBO(0xFF, 0x3E, 0x3E, 1.0)),
                      ),
                    ],
                  ),
                  const Spacer(),
                  PopupMenuButton(
                    icon: const Icon(
                      Icons.more_horiz,
                      color: Color.fromRGBO(0x7D, 0x7D, 0x7D, 1.0),
                    ),
                    itemBuilder: (context) {
                      return [];
                    },
                  ),
                ],
              ),
            ),
            if (!_loading && _messages.isEmpty && _otherProfile != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Send your first message to ${_otherProfile!.name}',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 23,
                          fontWeight: FontWeight.w400,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: listHeight,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  itemExtent: innerItemSize + 16,

                  itemCount: _messages.length,
                  //    padding: EdgeInsets.only(
                  //   top:
                  //       MediaQuery.of(context).padding.top + 64 + innerItemSize,
                  // ),
                  itemBuilder: (context, fakeIndex) {
                    // if (fakeIndex < 2) {
                    //   return const SizedBox.square(
                    //     dimension: innerItemSize,
                    //   );
                    // }
                    final index = fakeIndex;
                    final message = _messages.values.toList()[index];
                    final myUid = ref.read(userProvider).uid;
                    final fromMe = message.uid == myUid;
                    return Consumer(
                      builder: (context, ref, child) {
                        final height = listHeight;
                        const itemHeight = innerItemSize + 16;
                        final itemTopPixels = index * itemHeight;
                        final scrollPixels =
                            ref.watch(_scrollProvider) + listHeight;
                        itemTopPixels + height + itemHeight;
                        final runwayLength = height + itemHeight;
                        final runwayRatio =
                            1.0 - (scrollPixels - itemTopPixels) / runwayLength;
                        // if (index == 3 || index == 4) {
                        //   print(
                        //       '$index) Runway ratio is $runwayRatio, shift is ${100 * (0.5 - runwayRatio)}');
                        // }

                        final t = Matrix4.identity()
                          // Shift scaling origin down as it scrolls up, so items don't fly upwards
                          ..translate(
                              0.0,
                              (1 - runwayRatio) *
                                  0.5 *
                                  itemHeight *
                                  (1.0 - runwayRatio))
                          // Scale based on distance on the runway
                          ..scale(runwayRatio.clamp(0.0, double.infinity))
                          // Center all items in the list
                          ..translate(0.0, runwayLength * (0.5 - runwayRatio))
                          // Shift the whole thing down
                          ..translate(0.0, runwayLength * 0.1);

                        final x = runwayRatio;
                        final y1 = cos(2 * x - pi / 2);
                        final y2 = cos(8 * (x - 1 + pi / 16));
                        final y = x < pi / 4
                            ? y1
                            : (x < (1 - pi / 16))
                                ? 1.0
                                : y2;
                        final blur = 100.0 * (1 - y.clamp(0.0, 1.0));
                        return Transform(
                          transform: t,
                          alignment: Alignment.center,
                          origin: Offset(
                              0.0, scrollPixels - itemTopPixels - runwayLength),
                          child: Opacity(
                            opacity: y.clamp(0.0, 1.0),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: fromMe ? 64.0 : 0.0,
                            right: fromMe ? 0.0 : 64.0,
                          ),
                          child: StreamBuilder<PlaybackInfo>(
                            initialData: const PlaybackInfo(),
                            stream: _audio.playbackInfoStream,
                            builder: (context, snapshot) {
                              final playbackInfo = snapshot.requireData;
                              final isCurrent =
                                  _playbackMessageId == message.messageId;
                              final isPlaying = isCurrent &&
                                  playbackInfo.state == PlaybackState.playing;
                              final isLoading = isCurrent &&
                                  playbackInfo.state == PlaybackState.loading;
                              // return ColoredBox(
                              //   color: Colors.transparent,
                              //   child: Center(
                              //     child: Container(
                              //       width: innerItemSize,
                              //       height: innerItemSize,
                              //       decoration: BoxDecoration(
                              //         shape: BoxShape.circle,
                              //         color: (fromMe
                              //             ? Colors.blue
                              //             : (index == 4
                              //                 ? Colors.orange
                              //                 : Colors.pink)),
                              //       ),
                              //     ),
                              //   ),
                              // );
                              return ColoredBox(
                                color: Colors.transparent,
                                child: Center(
                                  child: _ChatMessage(
                                    photo: fromMe
                                        ? _myPhoto
                                        : _otherProfile?.photo,
                                    fromMe: fromMe,
                                    message: message,
                                    height: innerItemSize,
                                    isLoading: isLoading,
                                    frequenciesColor: isPlaying
                                        ? const Color.fromRGBO(
                                            0x00, 0xff, 0xef, 1.0)
                                        : const Color.fromRGBO(
                                            0xAF, 0xAF, 0xAF, 1.0),
                                    frequencies: isPlaying
                                        ? playbackInfo.frequencies
                                        : null,
                                    onPressed: () async {
                                      if (isPlaying) {
                                        _audio.stop();
                                        setState(
                                            () => _playbackMessageId = null);
                                      } else {
                                        setState(() => _playbackMessageId =
                                            message.messageId);
                                        await _audio.setUrl(message.content);
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
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
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
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
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

  void _submit(Uint8List audio, Duration duration) async {
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
    final atEnd = _scrollController.position.extentAfter == 0;
    setState(() {
      _messages[pendingId] = ChatMessage(
        uid: uid,
        date: DateTime.now().toUtc(),
        type: ChatType.audio,
        content: file.path,
        duration: duration,
        waveform: [],
        reactions: {},
      );
    });
    if (atEnd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    final api = GetIt.instance.get<Api>();
    final result = await api.sendMessage(
      uid,
      widget.otherUid,
      ChatType.audio,
      file.path,
    );

    GetIt.instance.get<Mixpanel>().track("send_message");

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => setState(() => _messages[pendingId] = r),
    );
  }

  void _scrollListener() {
    final offset = _scrollController.offset;
    ref.read(_scrollProvider.notifier).update(offset);

    final startDate = _messages.values.first.date;
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.forward &&
        _scrollController.position.extentBefore < 400 &&
        _messages.isNotEmpty &&
        !_loading) {
      setState(() => _loading = true);
      _fetchHistory(startDate: startDate).then((_) {
        if (mounted) {
          setState(() => _loading = false);
        }
      });
    }
  }

  void _fetchOtherProfile() async {
    final api = GetIt.instance.get<Api>();
    final result = await api.getProfile(widget.otherUid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => setState(() => _otherProfile = r),
    );
  }

  Future<void> _fetchHistory({DateTime? startDate}) async {
    final api = GetIt.instance.get<Api>();
    final result = await api.getMessages(
      ref.read(userProvider).uid,
      widget.otherUid,
      startDate: startDate,
    );
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (messages) {
        final entries = _messages.entries.toList();
        setState(() {
          entries
              .addAll(messages.map((e) => MapEntry(e.messageId!, e)).toList());
          _messages.clear();
          _messages.addEntries(entries);
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
                            message.waveform.map((e) => e.toDouble()).toList(),
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
                      formatDuration(message.duration),
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

class _FlowListItem extends StatelessWidget {
  final Alignment alignment;
  final double scrollConvergence;
  final double listBottomRatio;
  final double animationMultiplier;
  final double outerItemSize;
  final double innerItemSize;
  final WidgetBuilder builder;

  const _FlowListItem({
    super.key,
    required this.alignment,
    required this.scrollConvergence,
    required this.listBottomRatio,
    required this.animationMultiplier,
    required this.outerItemSize,
    required this.innerItemSize,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: outerItemSize,
      height: outerItemSize,
      color: Colors.orange.withOpacity(0.3),
      child: Builder(
        // Builder needed for parent OverflowBox context/size
        builder: (context) {
          return Flow(
            clipBehavior: Clip.none,
            delegate: _PerspectiveFlowDelegate(
              scrollable: Scrollable.of(context),
              listItemContext: context,
              alignment: alignment,
              outerItemSize: outerItemSize,
              convergencePercentage: scrollConvergence,
              listBottomRatio: listBottomRatio,
              animationOffsetX: 0,
              animationOffsetY: 0,
            ),
            children: [
              builder(context),
            ],
          );
        },
      ),
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

class _PerspectiveFlowDelegate extends FlowDelegate {
  final ScrollableState scrollable;
  final BuildContext listItemContext;
  final Alignment alignment;
  final double outerItemSize;
  final double convergencePercentage;
  final double listBottomRatio;
  final double animationOffsetX;
  final double animationOffsetY;

  _PerspectiveFlowDelegate({
    required this.scrollable,
    required this.listItemContext,
    required this.alignment,
    required this.outerItemSize,
    this.convergencePercentage = 1.0,
    required this.listBottomRatio,
    required this.animationOffsetX,
    required this.animationOffsetY,
  }) : super(repaint: scrollable.position);

  @override
  bool shouldRelayout(covariant _PerspectiveFlowDelegate oldDelegate) => true;

  @override
  void paintChildren(FlowPaintingContext context) {
    final scrollableBox = scrollable.context.findRenderObject() as RenderBox;
    final listItemBox = listItemContext.findRenderObject() as RenderBox;
    final listItemOffset = listItemBox.localToGlobal(
      listItemBox.size.centerLeft(Offset.zero),
      ancestor: scrollableBox,
    );

    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction =
        (listItemOffset.dy / viewportDimension); //.clamp(0.0, 1.0);
    final height = convergencePercentage * 2;
    final verticalAlignment =
        Alignment(scrollFraction * height - height / 2, 0);

    // final listItemSize = context.size;
    // final childRect = verticalAlignment.inscribe(
    //   backgroundSize,
    //   Offset.zero & listItemSize,
    // );

    final index =
        (scrollableBox.size.height / listItemBox.size.height * scrollFraction);

    final itemSize = listItemBox.size;
    final itemCenter = listItemBox.size.center(Offset.zero);

    final scale = scrollFraction;
    const innerItemSize = 80.0;
    final m = Matrix4.identity()
      // ..translate(
      //   animationOffsetX * scale,
      //   animationOffsetY * scale,
      // )
      // Center vertically
      ..translate(
        0.0,
        // (1 - listBottomRatio) * scrollableBox.size.height / 2 -
        //     scrollableBox.size.height * 0.2)
        -innerItemSize,
      )
      // Translate based on scroll fraction
      // ..translate(
      //   (me ? 1.0 : -1.0) *
      //       scrollFraction *
      //       scrollFraction *
      //       convergencePercentage *
      //       scrollableBox.size.width /
      //       2,
      //   -index * listItemBox.size.height +
      //       scrollFraction *
      //           scrollFraction *
      //           scrollableBox.size.height *
      //           listBottomRatio,
      // )

      ..translate(alignment.x * scrollFraction * innerItemSize / 2, 0.0)
      // Scale based on scroll fraction
      ..translate(itemSize.width / 2, itemSize.height / 2)
      ..scale(scale)
      ..translate(-itemSize.width / 2, -itemSize.height / 2);

    final x = scrollFraction;
    final y = -pow(2.0 * x * x * x - 1, 2.0) + 1.0;

    context.paintChild(
      0,
      transform: Matrix4.identity()
        ..translate(100.0, 100.0)
        ..scale(1.0, 2.0)
        ..translate(-100.0, -100.0),
      opacity: y,
    );
  }

  @override
  bool shouldRepaint(covariant _PerspectiveFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        listItemContext != oldDelegate.listItemContext ||
        convergencePercentage != oldDelegate.convergencePercentage ||
        listBottomRatio != oldDelegate.listBottomRatio ||
        animationOffsetX != oldDelegate.animationOffsetX ||
        animationOffsetY != oldDelegate.animationOffsetY;
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

class _ChatProfilePage extends StatefulWidget {
  final Profile profile;
  final DateTime endTime;
  final VoidCallback onShowMessages;
  const _ChatProfilePage({
    Key? key,
    required this.profile,
    required this.endTime,
    required this.onShowMessages,
  }) : super(key: key);

  @override
  State<_ChatProfilePage> createState() => _ChatProfilePageState();
}

class _ChatProfilePageState extends State<_ChatProfilePage> {
  bool _play = true;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          Expanded(
            child: ProfileView(
              profile: widget.profile,
              endTime: widget.endTime,
              interestedTab: HomeTab.friendships,
              play: _play,
            ),
          ),
          Container(
            height: 72,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onPressed: widget.onShowMessages,
                  child: Container(
                    width: 64,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: const Icon(
                      Icons.message,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Consumer(
                  builder: (context, ref, _) {
                    return Button(
                      onPressed: () {
                        setState(() => _play = false);
                        _call(
                          context: context,
                          ref: ref,
                          profile: widget.profile.toSimpleProfile(),
                          video: false,
                        );
                      },
                      child: Container(
                        width: 64,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                        ),
                        child: const Icon(
                          Icons.call,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Button(
                  onPressed: () {
                    GetIt.instance.get<Mixpanel>().track("video_call");
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Video calling coming soon'),
                      ),
                    );
                  },
                  child: Container(
                    width: 64,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(9)),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: Colors.white,
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
}

class _ScrollNotifier extends StateNotifier<double> {
  _ScrollNotifier() : super(0.0);

  void update(double offset) => state = offset;
}

void _call({
  required BuildContext context,
  required WidgetRef ref,
  required SimpleProfile profile,
  required bool video,
}) async {
  GetIt.instance.get<Mixpanel>().track("audio_call");
  final callManager = GetIt.instance.get<CallManager>();
  callManager.call(
    context: context,
    uid: ref.read(userProvider).uid,
    otherProfile: profile,
    video: video,
  );
  context.pushNamed('call');
}

class ChatPageArguments {
  final String otherUid;
  final Profile otherProfile;

  const ChatPageArguments({
    required this.otherUid,
    required this.otherProfile,
  });
}

enum CallProfileAction { call, block, report }
