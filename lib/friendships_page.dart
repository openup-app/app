import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/invite_page.dart';
import 'package:openup/main.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';

class FriendshipsPage extends StatefulWidget {
  final TempFriendshipsRefresh tempRefresh;
  const FriendshipsPage({
    Key? key,
    required this.tempRefresh,
  }) : super(key: key);

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
            style:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 24),
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
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color:
                                  const Color.fromRGBO(0x4A, 0x4A, 0x4A, 1.0),
                            ),
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
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                children: [
                  const TextSpan(text: 'To maintain '),
                  TextSpan(
                    text: 'friendships ',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'on openup, you must talk to '),
                  TextSpan(
                    text: 'each other ',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(
                      text:
                          'once every 7 days. Not doing so will result in your friendship '),
                  TextSpan(
                    text: 'falling apart (deleted)',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromRGBO(0xFF, 0x0, 0x0, 1.0),
                        ),
                  ),
                  const TextSpan(text: '. This app is for people who are '),
                  TextSpan(
                    text: 'serious ',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'about making '),
                  TextSpan(
                    text: 'friends',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          child: _ConversationList(
            filterString: _filterString,
            tempRefresh: widget.tempRefresh,
          ),
        ),
      ],
    );
  }
}

class _ConversationList extends ConsumerStatefulWidget {
  final String filterString;
  final TempFriendshipsRefresh tempRefresh;

  const _ConversationList({
    Key? key,
    this.filterString = "",
    required this.tempRefresh,
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
    widget.tempRefresh.addListener(_tempRefreshListener);
  }

  @override
  void dispose() {
    widget.tempRefresh.removeListener(_tempRefreshListener);
    super.dispose();
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

  void _tempRefreshListener() {
    if (mounted) {
      setState(() => _loading = true);
      _fetchConversations();
    }
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
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _fetchConversations();
                },
                child: Text(
                  'Refresh',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
                context.goNamed(
                  'invite',
                  params: {'uid': chatroom.profile.uid},
                  extra: chatroom.invitationAudio != null
                      ? InvitePageArgs(
                          chatroom.profile,
                          chatroom.invitationAudio!,
                        )
                      : null,
                );
              }

              if (open && mounted) {
                setState(() {
                  _chatrooms[index] =
                      _chatrooms[index].copyWith(unreadCount: 0);
                });
                FocusScope.of(context).unfocus();
                // ignore: unused_local_variable
                context.pushNamed(
                  'chat',
                  params: {'uid': chatroom.profile.uid},
                  extra: ChatPageArguments(
                    otherUid: chatroom.profile.uid,
                    otherProfile: chatroom.profile,
                    otherLocation: chatroom.location,
                    online: chatroom.online,
                    endTime: chatroom.endTime,
                  ),
                );
                // Auto-refresh when coming back from chat
                // TODO: When a chat push notificaiton can refresh the conversations, we SHOULD check the refreshChat variable
                if (mounted) {
                  setState(() => _loading = true);
                  _fetchConversations();
                }
              }
            },
            child: Stack(
              children: [
                SizedBox(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                      ),
                                );
                              } else if (chatroom.unreadCount > 0) {
                                return Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        Color.fromRGBO(0x00, 0x85, 0xFF, 1.0),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              chatroom.profile.name,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            AutoSizeText(
                              chatroom.location,
                              minFontSize: 10,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontWeight: FontWeight.w300,
                                    fontSize: 18,
                                  ),
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
                                  formatter: (remaining) =>
                                      formatCountdown(remaining),
                                  endTime: chatroom.endTime,
                                  onDone: () {
                                    setState(() => _chatrooms.removeWhere((c) =>
                                        c.profile.uid == chatroom.profile.uid));
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  topicLabel(chatroom.topic),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w300,
                                      ),
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
                Positioned(
                  left: 58,
                  top: -18,
                  width: 78,
                  height: 78,
                  child: OnlineIndicatorBuilder(
                    uid: chatroom.profile.uid,
                    builder: (context, online) {
                      return online
                          ? const OnlineIndicator()
                          : const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
