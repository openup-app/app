import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/call_manager.dart';
import 'package:openup/api/chat/chat_api2.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/home_screen.dart';
import 'package:openup/main.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_view.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/disable.dart';
import 'package:openup/widgets/tab_view.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/toggle_button.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String host;
  final int webPort;
  final int socketPort;
  final Profile otherProfile;
  final bool online;
  final DateTime endTime;

  const ChatPage({
    Key? key,
    required this.host,
    required this.webPort,
    required this.socketPort,
    required this.otherProfile,
    required this.online,
    required this.endTime,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatPage>
    with SingleTickerProviderStateMixin {
  final _kDateFormat = DateFormat('EEEE h:mm');

  late final ChatApi2 _chatApi;

  final _messages = <String, ChatMessage2>{};

  final _scrollController = ScrollController();

  bool _showChat = true;

  bool _loading = true;

  String? _myPhoto;

  bool _recording = false;
  bool? _unblur;

  final _audio = JustAudioAudioPlayer();
  String? _playbackMessageId;

  @override
  void initState() {
    super.initState();

    _chatApi = ChatApi2(
      host: widget.host,
      socketPort: widget.socketPort,
      uid: ref.read(userProvider).uid,
      otherUid: widget.otherProfile.uid,
      onMessage: (message) {
        setState(() => _messages[message.messageId!] = message);
      },
      onConnectionError: () {
        // TODO: Deal with connection error
      },
    );

    final profile = ref.read(userProvider).profile!;
    setState(() => _myPhoto = profile.photo);

    _fetchUnblurPhotosFor();
    _fetchHistory().then((value) {
      if (mounted) {
        setState(() => _loading = false);
      }
    });

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.black,
        leading: const SizedBox.shrink(),
        title: Text(
          'Growing Friendships',
          style: Theming.of(context)
              .text
              .body
              .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
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
                      onSelected: (first) => setState(() => _showChat = first),
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
                    profile: widget.otherProfile,
                    endTime: widget.endTime,
                    onShowMessages: () {
                      setState(() => _showChat = true);
                    },
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 24),
                        Container(
                          width: 16,
                          alignment: Alignment.center,
                          child:
                              !widget.online ? const OnlineIndicator() : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AutoSizeText(
                                widget.otherProfile.name,
                                minFontSize: 9,
                                maxFontSize: 20,
                                overflow: TextOverflow.ellipsis,
                                style: Theming.of(context)
                                    .text
                                    .body
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              AutoSizeText(
                                widget.otherProfile.location,
                                minFontSize: 9,
                                maxFontSize: 16,
                                overflow: TextOverflow.ellipsis,
                                style: Theming.of(context)
                                    .text
                                    .body
                                    .copyWith(fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                        if (ref.watch(userProvider).profile?.blurPhotos ==
                            true) ...[
                          const SizedBox(width: 4),
                          Text(
                            'Reveal Pictures',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 16, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(width: 9),
                          Builder(
                            builder: (context) {
                              final unblur = _unblur;
                              if (unblur == null) {
                                return const Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 15.5),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: Center(
                                      child: LoadingIndicator(
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ToggleButton(
                                value: unblur,
                                onChanged: (value) {
                                  final api = GetIt.instance.get<Api>();
                                  api.updateUnblurPhotosFor(
                                    ref.read(userProvider).uid,
                                    widget.otherProfile.uid,
                                    value,
                                  );
                                  setState(() => _unblur = value);
                                },
                              );
                            },
                          ),
                        ],
                        const SizedBox(width: 16),
                      ],
                    ),
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
                              itemCount: _messages.length + (_loading ? 1 : 0),
                              itemBuilder: (context, forwardIndex) {
                                var index =
                                    _messages.values.length - forwardIndex - 1;
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

                                final messageReady = message.messageId != null;

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
                                        final blurEnabled =
                                            ref.watch(userProvider.select((p) {
                                          return p.profile?.blurPhotos == true;
                                        }));
                                        final unblur = _unblur == true;
                                        final blurMyPhotos =
                                            blurEnabled && !unblur;
                                        switch (message.type) {
                                          case ChatType2.audio:
                                            return Builder(
                                              builder: (context) {
                                                if (_playbackMessageId ==
                                                        null ||
                                                    _playbackMessageId !=
                                                        message.messageId) {
                                                  return AudioChatMessage(
                                                    key: Key(
                                                        'audio_${message.messageId}'),
                                                    audioUrl: message.content,
                                                    photoUrl: fromMe
                                                        ? _myPhoto ?? ''
                                                        : widget
                                                            .otherProfile.photo,
                                                    blurPhotos: fromMe
                                                        ? blurMyPhotos
                                                        : widget.otherProfile
                                                            .blurPhotos,
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
                                                  );
                                                }
                                                return StreamBuilder<
                                                    PlaybackInfo>(
                                                  stream:
                                                      _audio.playbackInfoStream,
                                                  initialData:
                                                      const PlaybackInfo(),
                                                  builder: (context, snapshot) {
                                                    final playbackInfo =
                                                        snapshot.requireData;
                                                    return AudioChatMessage(
                                                      key: Key(
                                                          'audio_${message.messageId}'),
                                                      audioUrl: message.content,
                                                      photoUrl: fromMe
                                                          ? _myPhoto ?? ''
                                                          : widget.otherProfile
                                                              .photo,
                                                      blurPhotos: fromMe
                                                          ? blurMyPhotos
                                                          : widget.otherProfile
                                                              .blurPhotos,
                                                      date: _buildDateText(
                                                          message.date),
                                                      fromMe: fromMe,
                                                      playbackInfo:
                                                          playbackInfo,
                                                      onPlay: () =>
                                                          _audio.play(),
                                                      onPause: () =>
                                                          _audio.pause(),
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
                          if (!_loading && _messages.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  'Send your first message to ${widget.otherProfile.name}',
                                  style: Theming.of(context).text.bodySecondary,
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Button(
                                    onPressed: () {
                                      _call(
                                        context: context,
                                        ref: ref,
                                        profile: widget.otherProfile
                                            .toSimpleProfile(),
                                        video: false,
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.call,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: RecordButtonChat(
                                    onSubmit: _submit,
                                    onBeginRecording: () =>
                                        setState(() => _recording = true),
                                    onEndRecording: () =>
                                        setState(() => _recording = false),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Button(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Video calling coming soon'),
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.videocam,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                ),
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
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w300),
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
          fontWeight: FontWeight.w400,
          color: Colors.white.withOpacity(opacity)),
    );
  }

  void _submit(String content) async {
    const uuid = Uuid();
    final pendingId = uuid.v4();
    final uid = ref.read(userProvider).uid;
    setState(() {
      _messages[pendingId] = ChatMessage2(
        uid: uid,
        date: DateTime.now().toUtc(),
        type: ChatType2.audio,
        content: content,
      );
    });

    final api = GetIt.instance.get<Api>();
    final result = await api.sendMessage2(
        uid, widget.otherProfile.uid, ChatType2.audio, content);

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

  void _fetchUnblurPhotosFor() async {
    final api = GetIt.instance.get<Api>();
    final result = await api.getUnblurPhotosFor(
        ref.read(userProvider).uid, widget.otherProfile.uid);
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
    final result = await api.getMessages2(
      ref.read(userProvider).uid,
      widget.otherProfile.uid,
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
  final callManager = GetIt.instance.get<CallManager>();
  callManager.call(
    context: context,
    uid: ref.read(userProvider).uid,
    otherProfile: profile,
    video: video,
  );
  rootNavigatorKey.currentState?.pushNamed('call');
}

class ChatPageArguments {
  final String otherUid;
  final Profile otherProfile;
  final String otherLocation;
  final bool online;
  final DateTime endTime;

  const ChatPageArguments({
    required this.otherUid,
    required this.otherProfile,
    required this.otherLocation,
    required this.online,
    required this.endTime,
  });
}
