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
import 'package:openup/main.dart';
import 'package:openup/profile_view.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/chat_message.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/disable.dart';
import 'package:openup/widgets/tab_view.dart';
import 'package:openup/widgets/theming.dart';
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

  Profile? _profile;
  String? _myPhoto;

  bool _recording = false;

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

    _fetchHistory();

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _chatApi.dispose();
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        title: TabView(
          firstSelected: _showChat,
          firstLabel: 'Messages',
          secondLabel: 'Profile',
          onSelected: (first) => setState(() => _showChat = first),
        ),
      ),
      body: Builder(builder: (context) {
        if (!_showChat) {
          return _ChatProfilePage(
            profile: widget.otherProfile,
            endTime: widget.endTime,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: widget.online
                      ? const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(
                      widget.otherProfile.name,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      widget.otherProfile.location,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
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
                        bottom: 80,
                      ),
                      itemCount: _messages.length + (_loading ? 1 : 0),
                      itemBuilder: (context, forwardIndex) {
                        var index = _messages.values.length - forwardIndex - 1;
                        if (_loading && forwardIndex == _messages.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final message = _messages.values.toList()[index];
                        final uid = ref.read(userProvider).uid;
                        final fromMe = message.uid == uid;

                        final messageReady = message.messageId != null;

                        return Container(
                          key: messageReady ? Key(message.messageId!) : null,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          alignment: fromMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Disable(
                            disabling: !messageReady,
                            child: Builder(
                              builder: (context) {
                                switch (message.type) {
                                  case ChatType2.audio:
                                    return AudioChatMessage(
                                      ready: messageReady,
                                      audioUrl: message.content,
                                      photoUrl: fromMe
                                          ? _myPhoto ?? ''
                                          : widget.otherProfile.photo,
                                      date: _buildDateText(message.date),
                                      fromMe: fromMe,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Send your first message to ${_profile != null ? _profile!.name : ''}',
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Button(
                            onPressed: () {
                              final callManager =
                                  GetIt.instance.get<CallManager>();
                              callManager.call(
                                context: context,
                                uid: ref.read(userProvider).uid,
                                otherProfile:
                                    widget.otherProfile.toSimpleProfile(),
                                video: false,
                              );
                              rootNavigatorKey.currentState?.pushNamed('call');
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Button(
                            onPressed: () {
                              final callManager =
                                  GetIt.instance.get<CallManager>();
                              callManager.call(
                                context: context,
                                uid: ref.read(userProvider).uid,
                                otherProfile:
                                    widget.otherProfile.toSimpleProfile(),
                                video: true,
                              );
                              rootNavigatorKey.currentState?.pushNamed('call');
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
                      'voice messages can only be upto 30 seconds',
                      textAlign: TextAlign.center,
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 14, fontWeight: FontWeight.w300),
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
      }),
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
      _fetchHistory(startDate: startDate);
    }
  }

  void _fetchHistory({DateTime? startDate}) async {
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

    setState(() => _loading = false);
  }

  void _call(
    Profile profile, {
    required bool video,
  }) async {
    // final profile = _profile;
    // if (profile == null) {
    //   return;
    // }

    // const purpose = 'friends';
    // final route = video ? '$purpose-video-call' : '$purpose-voice-call';
    // final api = GetIt.instance.get<Api>();
    // final result = await api.call(
    //   profile.uid,
    //   video,
    //   group: false,
    // );
    // if (mounted) {
    //   result.fold((l) {
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       SnackBar(
    //         content: Text('Failed to call ${profile.name}'),
    //       ),
    //     );
    //   }, (rid) {
    //     Navigator.of(context).pushNamed(
    //       route,
    //       arguments: CallPageArguments(
    //         rid: rid,
    //         profiles: [profile.toSimpleProfile()],
    //         serious: false,
    //       ),
    //     );
    //   });
    // }
  }
}

class _ChatProfilePage extends StatelessWidget {
  final Profile profile;
  final DateTime endTime;
  const _ChatProfilePage({
    Key? key,
    required this.profile,
    required this.endTime,
  }) : super(key: key);

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
              profile: profile,
              endTime: endTime,
            ),
          ),
          Container(
            height: 72,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Button(
                  onPressed: () {},
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
                Button(
                  onPressed: () {
                    // callSystemKey.currentState?.call(
                    //   context,
                    //   SimpleProfile(
                    //     uid: profile.uid,
                    //     name: profile.name,
                    //     photo: profile.photo,
                    //   ),
                    // );
                    Navigator.of(context).pushNamed('call');
                  },
                  // child: Container(
                  //   width: 64,
                  //   height: 46,
                  //   decoration: const BoxDecoration(
                  //     color: Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
                  //     borderRadius: BorderRadius.all(Radius.circular(9)),
                  //   ),
                  //   child: const Icon(
                  //     Icons.call,
                  //     color: Colors.white,
                  //   ),
                  // ),
                  child: FlutterLogo(),
                ),
                const SizedBox(width: 16),
                Button(
                  onPressed: () {},
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
