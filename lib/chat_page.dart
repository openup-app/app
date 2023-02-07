import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/main.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_view.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/disable.dart';
import 'package:openup/widgets/screenshot.dart';
import 'package:openup/widgets/tab_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

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
  final _kDateFormat = DateFormat('EEEE h:mm');

  late final ChatApi _chatApi;

  final _messages = <String, ChatMessage>{};

  final _scrollController = ScrollController();

  bool _showChat = true;

  bool _loading = true;

  Profile? _otherProfile;

  DateTime? _endTime;

  String? _myPhoto;

  bool _recording = false;
  bool? _unblur;

  final _audio = JustAudioAudioPlayer();
  String? _playbackMessageId;

  final _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();

    _chatApi = ChatApi(
      host: widget.host,
      socketPort: widget.socketPort,
      uid: ref.read(userProvider).uid,
      otherUid: widget.otherUid,
      onMessage: (message) {
        setState(() => _messages[message.messageId!] = message);
      },
      onConnectionError: () {
        // TODO: Deal with connection error
      },
    );

    final profile = Profile(
      blurPhotos: false,
      location: 'Test',
      name: 'Test user',
      photo: 'https://picsum.photos/200/300',
      gallery: [
        'https://picsum.photos/200/300',
        'https://picsum.photos/200/400',
      ],
      topic: Topic.backpacking,
      uid: 'abcd',
      favorite: false,
      mutualFriends: [],
    );

    // final profile = ref.read(userProvider).profile!;
    setState(() => _myPhoto = profile.photo);

    _fetchUnblurPhotosFor();
    _fetchHistory().then((value) {
      if (mounted) {
        setState(() => _loading = false);
      }
    });

    if (widget.otherProfile != null) {
      _otherProfile = widget.otherProfile;
    } else {
      _fetchOtherProfile();
    }

    if (widget.endTime != null) {
      _endTime = widget.endTime;
    } else {
      _fetchEndTime();
    }

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _chatApi.dispose();
    _audio.dispose();
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          leading: const SizedBox.shrink(),
          title: Row(
            children: [
              Container(
                width: 45,
                height: 45,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: widget.otherProfile?.photo == null
                    ? Image.network(
                        widget.otherProfile!.photo,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 9),
              Text(
                widget.otherProfile?.name ?? '',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w300,
                    color: const Color.fromRGBO(0x96, 0x96, 0x96, 1.0)),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  const Positioned(
                    top: 0,
                    bottom: 0,
                    left: 4,
                    child: BackIconButton(),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: TabView(
                        firstSelected: _showChat,
                        firstLabel: 'Messages',
                        secondLabel: 'Profile',
                        onSelected: (first) {
                          if (first) {
                            setState(() => _showChat = true);
                          } else {
                            if (_otherProfile != null && _endTime != null) {
                              setState(() => _showChat = false);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!_showChat) {
                    return _ChatProfilePage(
                      profile: _otherProfile!,
                      endTime: _endTime!,
                      onShowMessages: () {
                        setState(() => _showChat = true);
                      },
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Scrollbar(
                              controller: _scrollController,
                              child: ListView.builder(
                                controller: _scrollController,
                                reverse: true,
                                padding: EdgeInsets.only(
                                  top: MediaQuery.of(context).padding.top + 64,
                                ),
                                itemCount:
                                    _messages.length + (_loading ? 1 : 0),
                                itemBuilder: (context, forwardIndex) {
                                  var index = _messages.values.length -
                                      forwardIndex -
                                      1;
                                  if (_loading &&
                                      forwardIndex == _messages.length) {
                                    return const Center(
                                      child: LoadingIndicator(),
                                    );
                                  }
                                  final message =
                                      _messages.values.toList()[index];
                                  final uid = ref.read(userProvider).uid;
                                  final fromMe = message.uid == uid;

                                  final messageReady =
                                      message.messageId != null;
                                  final playingThisMessage =
                                      _playbackMessageId == message.messageId;

                                  return Container(
                                    key: messageReady
                                        ? Key(message.messageId!)
                                        : null,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    alignment: fromMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Disable(
                                      disabling: !messageReady,
                                      child: Consumer(
                                        builder: (context, ref, _) {
                                          final blurEnabled = ref
                                              .watch(userProvider.select((p) {
                                            return p.profile?.blurPhotos ==
                                                true;
                                          }));
                                          final unblur = _unblur == true;
                                          final blurMyPhotos =
                                              blurEnabled && !unblur;
                                          switch (message.type) {
                                            case ChatType.audio:
                                              return Builder(
                                                builder: (context) {
                                                  if (!playingThisMessage) {
                                                    return AudioChatMessage(
                                                      key: Key(
                                                          'audio_${message.messageId}'),
                                                      audioUrl: message.content,
                                                      duration:
                                                          message.duration,
                                                      photoUrl: fromMe
                                                          ? _myPhoto ?? ''
                                                          : (widget.otherProfile
                                                                  ?.photo ??
                                                              ''),
                                                      blurPhotos: fromMe
                                                          ? blurMyPhotos
                                                          : (_otherProfile
                                                                  ?.blurPhotos ??
                                                              true),
                                                      date: _buildDateText(
                                                          message.date),
                                                      fromMe: fromMe,
                                                      playbackInfo:
                                                          const PlaybackInfo(),
                                                      onPlay: () => setState(
                                                        () {
                                                          _playbackMessageId =
                                                              message.messageId;
                                                          _audio.setUrl(
                                                              message.content);
                                                          _audio.play();
                                                        },
                                                      ),
                                                      onPause: () {},
                                                      onSeek: null,
                                                    );
                                                  }
                                                  return StreamBuilder<
                                                      PlaybackInfo>(
                                                    stream: _audio
                                                        .playbackInfoStream,
                                                    initialData:
                                                        const PlaybackInfo(),
                                                    builder:
                                                        (context, snapshot) {
                                                      final playbackInfo =
                                                          snapshot.requireData;
                                                      return AudioChatMessage(
                                                        key: Key(
                                                            'audio_${message.messageId}'),
                                                        audioUrl:
                                                            message.content,
                                                        duration:
                                                            message.duration,
                                                        photoUrl: fromMe
                                                            ? _myPhoto ?? ''
                                                            : (_otherProfile
                                                                    ?.photo ??
                                                                ''),
                                                        blurPhotos: fromMe
                                                            ? blurMyPhotos
                                                            : (_otherProfile
                                                                    ?.blurPhotos ??
                                                                true),
                                                        date: _buildDateText(
                                                            message.date),
                                                        fromMe: fromMe,
                                                        playbackInfo:
                                                            playbackInfo,
                                                        onPlay: () =>
                                                            _audio.play(),
                                                        onPause: () =>
                                                            _audio.pause(),
                                                        onSeek:
                                                            !playingThisMessage
                                                                ? null
                                                                : (position) =>
                                                                    _audio.seek(
                                                                        position),
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (!_loading &&
                                _messages.isEmpty &&
                                _otherProfile != null)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(
                                    'Send your first message to ${_otherProfile!.name}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w400,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        height: 95,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.fingerprint,
                                    size: 48,
                                    color:
                                        Color.fromRGBO(0xFF, 0xC7, 0xC7, 1.0),
                                  ),
                                  const Spacer(),
                                  SizedBox(
                                    width: 180,
                                    child: _RecordButton(
                                      onPressed: () async {
                                        final audioFile =
                                            await _showRecordPanel(context);
                                        if (audioFile != null && mounted) {
                                          _submit(audioFile.path);
                                        }
                                      },
                                    ),
                                  ),
                                  const Spacer(),
                                  MenuButton(
                                    onPressed: () async {
                                      final screenshot =
                                          await _screenshotController
                                              .takeScreenshot();
                                      if (!mounted) {
                                        return;
                                      }
                                      menuKey.currentState
                                          ?.showMenu(screenshot);
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Visibility(
                              visible: _recording,
                              maintainAnimation: true,
                              maintainState: true,
                              maintainSize: true,
                              child: Text(
                                'voice messages can only be upto 60 seconds',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w300,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom,
                      ),
                    ],
                  );
                },
              ),
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
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.white.withOpacity(opacity),
          ),
    );
  }

  Future<File?> _showRecordPanel(BuildContext context) async {
    final audio = await showModalBottomSheet<Uint8List>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return Surface(
          child: RecordPanelContents(
            onSubmit: (audio) => Navigator.of(context).pop(audio),
          ),
        );
      },
    );

    if (audio == null || !mounted) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(
        tempDir.path, 'chats', '${DateTime.now().toIso8601String()}.m4a'));
    await file.writeAsBytes(audio);
    return file;
  }

  void _submit(String content) async {
    const uuid = Uuid();
    final pendingId = uuid.v4();
    final uid = ref.read(userProvider).uid;
    setState(() {
      _messages[pendingId] = ChatMessage(
        uid: uid,
        date: DateTime.now().toUtc(),
        type: ChatType.audio,
        content: content,
      );
    });

    final api = GetIt.instance.get<Api>();
    final result =
        await api.sendMessage(uid, widget.otherUid, ChatType.audio, content);

    GetIt.instance.get<Mixpanel>().track("send_message");

    if (!mounted) {
      return;
    }

    result.fold((l) {
      // TODO;
    }, (r) {
      setState(() => _messages[pendingId] = r);
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  void _scrollListener() {
    final startDate = _messages.values.first.date;
    if (_scrollController.position.userScrollDirection ==
            ScrollDirection.reverse &&
        _scrollController.position.extentAfter < 200 &&
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

  void _fetchEndTime() async {
    final api = GetIt.instance.get<Api>();
    final result =
        await api.getChatroom(ref.read(userProvider).uid, widget.otherUid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => setState(() => _endTime = r.endTime),
    );
  }

  void _fetchUnblurPhotosFor() async {
    final api = GetIt.instance.get<Api>();
    final result = await api.getUnblurPhotosFor(
        ref.read(userProvider).uid, widget.otherUid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        setState(() => _unblur = r);
      },
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
          entries.insertAll(0, messages.map((e) => MapEntry(e.messageId!, e)));
          _messages.clear();
          _messages.addEntries(entries);
        });
      },
    );
  }
}

class _RecordButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _RecordButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 156,
        height: 50,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0xFF, 0x00, 0x00, 0.5),
          borderRadius: BorderRadius.all(
            Radius.circular(72),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mic_none),
            const SizedBox(width: 4),
            Text(
              'send invitation',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
            ),
          ],
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
