import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/invite_page.dart';
import 'package:openup/main.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/screenshot.dart';

class RelationshipsPage extends ConsumerStatefulWidget {
  final TempFriendshipsRefresh tempRefresh;
  const RelationshipsPage({
    Key? key,
    required this.tempRefresh,
  }) : super(key: key);

  @override
  ConsumerState<RelationshipsPage> createState() => _RelationshipsPageState();
}

class _RelationshipsPageState extends ConsumerState<RelationshipsPage> {
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();
  bool _hasFocus = false;
  String _filterString = "";
  final _screenshotController = ScreenshotController();

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
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    if (!loggedIn) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login to create relationships'),
            ElevatedButton(
              onPressed: () => context.pushNamed('signup'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

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

    return Screenshot(
      controller: _screenshotController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color.fromRGBO(0xFF, 0x76, 0x76, 1.0),
                    Color.fromRGBO(0xFF, 0x3E, 0x3E, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                'Growing Relationships',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 28, fontWeight: FontWeight.w300),
              ),
            ),
          ),
          Container(
            height: 31,
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0xD9, 0xD9, 0xD9, 0.1),
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: TextFormField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Search',
                          hintStyle:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white,
                                  ),
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
          if (_filterString.isEmpty)
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 82,
                        height: 110,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromRGBO(0xFF, 0x5F, 0x5F, 1.0),
                            width: 2,
                          ),
                          borderRadius:
                              const BorderRadius.all(Radius.circular(11)),
                        ),
                        margin: const EdgeInsets.all(9),
                        child: Image.network(
                          profile.photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 82,
                        child: Text(
                          profile.name,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w200,
                                    color: Colors.white,
                                  ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          if (_filterString.isEmpty) const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                _ConversationList(
                  filterString: _filterString,
                  tempRefresh: widget.tempRefresh,
                ),
                Positioned(
                  right: 25,
                  bottom: 40 + MediaQuery.of(context).padding.bottom,
                  child: MenuButton(
                    onPressed: () async {
                      final screenshot =
                          await _screenshotController.takeScreenshot();
                      if (!mounted) {
                        return;
                      }
                      menuKey.currentState?.showMenu(screenshot);
                    },
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

    final count = 20;
    _chatrooms = List.generate(20 + 3, (index) {
      return Chatroom(
        invitationAudio: null,
        endTime: DateTime.now().add(const Duration(days: 3)),
        location: 'Location',
        profile: profile,
        state: ChatroomState.accepted,
        unreadCount: 0,
      );
    });

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
        separatorBuilder: (_, index) {
          final suggestedFriendDivider = index == count;
          return Divider(
            color: suggestedFriendDivider
                ? const Color.fromRGBO(0x99, 0x91, 0x91, 1.0)
                : const Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
            height: suggestedFriendDivider ? 3 : 1,
            indent: 29,
          );
        },
        itemBuilder: (context, index) {
          final suggestedFriend = index > count;

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
                  params: {'uid': 'ZASK6WFfS0VmJJboUxTzxQYFP212'},
                  extra: ChatPageArguments(
                    otherUid: 'ZASK6WFfS0VmJJboUxTzxQYFP212',
                    otherProfile: chatroom.profile
                        .copyWith(uid: 'ZASK6WFfS0VmJJboUxTzxQYFP212'),
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
                  height: 140,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 29,
                        child: Center(
                          child: Builder(
                            builder: (context) {
                              if (chatroom.unreadCount != 0) {
                                return Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color.fromRGBO(0xF6, 0x28, 0x28, 1.0),
                                        Color.fromRGBO(0xFF, 0x5F, 0x5F, 1.0),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      Container(
                        width: 82,
                        height: 110,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(11)),
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
                            const SizedBox(height: 2),
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
                      const Icon(
                        Icons.chevron_right,
                        color: Color.fromRGBO(0x7D, 0x7D, 0x7D, 1.0),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
                if (suggestedFriend || chatroom.unreadCount > 0)
                  Positioned(
                    right: 41,
                    bottom: 16,
                    child: Text(
                      suggestedFriend ? 'Suggested Friend' : 'New message',
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
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
