import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/profile_screen.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/theming.dart';

class FriendshipsPage extends StatefulWidget {
  const FriendshipsPage({Key? key}) : super(key: key);

  @override
  State<FriendshipsPage> createState() => _FriendshipsPageState();
}

class _FriendshipsPageState extends State<FriendshipsPage> {
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  bool _hasFocus = false;
  String _filterString = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_filterString != _searchController.text) {
        setState(() => _filterString = _searchController.text);
      }
    });

    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus != _hasFocus) {
        setState(() => _hasFocus = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(
          centerTitle: true,
          backgroundColor: Colors.black,
          title: Text(
            'Growing Friendships',
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          height: 43,
          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(),
            borderRadius: const BorderRadius.all(Radius.circular(24)),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 33.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search',
                        hintStyle: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: const Color.fromRGBO(0x4A, 0x4A, 0x4A, 1.0)),
                      ),
                    ),
                  ),
                  if (_filterString.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Button(
                        onPressed: () {
                          setState(() => _searchController.text = "");
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_filterString.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              text: TextSpan(
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                children: [
                  const TextSpan(text: 'To maintain '),
                  TextSpan(
                    text: 'friendships ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'on openup, you must talk to '),
                  TextSpan(
                    text: 'each other ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(
                      text:
                          'once every 72 hours. Not doing so will result in your friendship '),
                  TextSpan(
                    text: 'falling apart (deleted)',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromRGBO(0xFF, 0x0, 0x0, 1.0),
                        ),
                  ),
                  const TextSpan(text: '. This app is for people who are '),
                  TextSpan(
                    text: 'serious ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'about making '),
                  TextSpan(
                    text: 'friends',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        if (_filterString.isEmpty) const SizedBox(height: 16),
        Expanded(
          child: _ConversationList(filterString: _filterString),
        ),
      ],
    );
  }
}

class _ConversationList extends ConsumerStatefulWidget {
  final String filterString;
  const _ConversationList({
    Key? key,
    this.filterString = "",
  }) : super(key: key);

  @override
  ConsumerState<_ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends ConsumerState<_ConversationList> {
  bool _loading = true;
  var _chatrooms = <Chatroom>[];

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;
    final result = await api.getChatrooms(uid);

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    result.fold(
      (l) {
        final message = errorToMessage(l);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      (r) => setState(() => _chatrooms = r),
    );
  }

  String _waitDurationText(String name, Duration waitDuration) {
    final hoursInt = waitDuration.inHours;
    final hours = hoursInt <= 1 ? '1' : hoursInt.toString();
    return 'You can invite $name again in $hours ${hoursInt <= 1 ? 'hour' : 'hours'}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SafeArea(
        child: Center(
          child: LoadingIndicator(),
        ),
      );
    }
    if (_chatrooms.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Invite someone to chat,\nthen continue the conversation here',
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _fetchConversations();
                },
                child: Text('Refresh', style: Theming.of(context).text.body),
              ),
            ],
          ),
        ),
      );
    }

    final filteredChatrooms = _chatrooms
        .where((c) => c.profile.name
            .toLowerCase()
            .contains(widget.filterString.toLowerCase()))
        .toList();

    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        itemCount: filteredChatrooms.length,
        separatorBuilder: (context, _) {
          return Container(
            height: 1,
            margin: const EdgeInsets.only(left: 99),
            color: const Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
          );
        },
        itemBuilder: (context, index) {
          final chatroom = filteredChatrooms[index];
          return Button(
            onPressed: () async {
              bool open = false;
              final index = _chatrooms.indexOf(chatroom);

              final now = DateTime.now();
              final inviteAgainTime =
                  chatroom.endTime.subtract(const Duration(days: 2));
              if (chatroom.state == ChatroomState.accepted ||
                  now.isAfter(inviteAgainTime)) {
                open = true;
              } else if (chatroom.state == ChatroomState.pending &&
                  inviteAgainTime.isAfter(now)) {
                final waitDuration = inviteAgainTime.difference(now).abs();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        _waitDurationText(chatroom.profile.name, waitDuration)),
                  ),
                );
              } else if (chatroom.state == ChatroomState.invitation) {
                final accept = await rootNavigatorKey.currentState?.push<bool>(
                  MaterialPageRoute(
                    builder: (context) {
                      return _InvitationPage(
                        profile: chatroom.profile,
                        invitationAudio: chatroom.invitationAudio,
                        online: chatroom.online,
                      );
                    },
                  ),
                );
                if (accept != null) {
                  if (accept) {
                    open = true;
                    setState(() {
                      _chatrooms[index] =
                          chatroom.copyWith(state: ChatroomState.accepted);
                    });
                  } else {
                    setState(() => _chatrooms.removeAt(index));
                  }
                }
              }

              if (open && mounted) {
                setState(() {
                  _chatrooms[index] =
                      _chatrooms[index].copyWith(unreadCount: 0);
                });
                FocusScope.of(context).unfocus();
                final refreshChat = await Navigator.of(context).pushNamed(
                  'chat',
                  arguments: ChatPageArguments(
                    otherUid: chatroom.profile.uid,
                    otherProfile: chatroom.profile,
                    otherLocation: chatroom.location,
                    online: chatroom.online,
                    endTime: chatroom.endTime,
                  ),
                );
                if (refreshChat == true && mounted) {
                  setState(() => _loading = true);
                  _fetchConversations();
                }
              }
            },
            child: SizedBox(
              height: 86,
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          if (chatroom.state == ChatroomState.invitation) {
                            return Text(
                              'new',
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w300),
                            );
                          } else if (chatroom.unreadCount > 0) {
                            return Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      Container(
                        width: 65,
                        height: 65,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ProfileImage(
                          chatroom.profile.photo,
                          blur: chatroom.profile.blurPhotos,
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: chatroom.online
                              ? const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          chatroom.profile.name,
                          style: Theming.of(context).text.body,
                        ),
                        const SizedBox(height: 4),
                        AutoSizeText(
                          chatroom.location,
                          maxFontSize: 16,
                          maxLines: 1,
                          style: Theming.of(context)
                              .text
                              .body
                              .copyWith(fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CountdownTimer(
                              endTime: chatroom.endTime,
                              onDone: () => setState(() =>
                                  _chatrooms.removeWhere((c) =>
                                      c.profile.uid == chatroom.profile.uid)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topicLabel(chatroom.topic),
                              style: Theming.of(context).text.body.copyWith(
                                  fontSize: 16, fontWeight: FontWeight.w300),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InvitationPage extends ConsumerStatefulWidget {
  final Profile profile;
  final String? invitationAudio;
  final bool online;
  const _InvitationPage({
    super.key,
    required this.profile,
    required this.invitationAudio,
    required this.online,
  });

  @override
  ConsumerState<_InvitationPage> createState() => __InvitationPageState();
}

class __InvitationPageState extends ConsumerState<_InvitationPage> {
  final _player = JustAudioAudioPlayer();

  @override
  void initState() {
    super.initState();
    final invitationAudio = widget.invitationAudio;
    if (invitationAudio != null) {
      _player.setUrl(invitationAudio);
      _player.play(loop: true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
              Color.fromRGBO(0x6F, 0x00, 0x00, 1.0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                'A personal invitation for you',
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: BackIconButton(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.online) const OnlineIndicator(),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      AutoSizeText(
                        widget.profile.name,
                        minFontSize: 16,
                        maxFontSize: 20,
                        overflow: TextOverflow.ellipsis,
                        style: Theming.of(context)
                            .text
                            .body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      AutoSizeText(
                        widget.profile.location,
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
                ],
              ),
              const SizedBox(height: 31),
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Gallery(
                    gallery: widget.profile.gallery,
                    withWideBlur: false,
                    slideshow: true,
                    blurPhotos: widget.profile.blurPhotos,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<PlaybackInfo>(
                stream: _player.playbackInfoStream,
                initialData: const PlaybackInfo(),
                builder: (context, snapshot) {
                  final value = snapshot.requireData;
                  final position = value.position.inMilliseconds;
                  final duration = value.duration.inMilliseconds;
                  final ratio = duration == 0 ? 0.0 : position / duration;
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: ratio < 0 ? 0 : ratio,
                      child: Container(
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                          color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                              blurRadius: 4,
                              offset: Offset(0.0, 4.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 31),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Button(
                    onPressed: () {
                      final uid = ref.read(userProvider).uid;
                      final api = GetIt.instance.get<Api>();
                      api.acceptInvitation(uid, widget.profile.uid);
                      rootNavigatorKey.currentState?.pop(true);
                    },
                    child: Container(
                      width: 111,
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Accept',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.black),
                      ),
                    ),
                  ),
                  Button(
                    onPressed: () {
                      final uid = ref.read(userProvider).uid;
                      final api = GetIt.instance.get<Api>();
                      api.declineInvitation(uid, widget.profile.uid);
                      rootNavigatorKey.currentState?.pop(false);
                    },
                    child: Container(
                      width: 111,
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Reject',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 31),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 291,
                  ),
                  child: Text(
                    'Accept and begin chatting now, reject and they can send you another message tomorrow.',
                    textAlign: TextAlign.center,
                    style: Theming.of(context).text.body.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: const Color.fromRGBO(0xDE, 0xDE, 0xDE, 1.0)),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
