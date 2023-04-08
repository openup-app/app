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
import 'package:openup/view_collection_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';

class RelationshipsPage extends ConsumerStatefulWidget {
  final TempFriendshipsRefresh tempRefresh;
  const RelationshipsPage({
    Key? key,
    required this.tempRefresh,
  }) : super(key: key);

  @override
  ConsumerState<RelationshipsPage> createState() => _RelationshipsPageState();
}

class _RelationshipsPageState extends ConsumerState<RelationshipsPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _filterString = "";

  final _collections = <Collection>[];
  late final _tabController = TabController(
    length: 2,
    vsync: this,
  );

  List<Chatroom>? _chatrooms;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_filterString != _searchController.text) {
        setState(() => _filterString = _searchController.text);
      }
    });

    widget.tempRefresh.addListener(_fetchChatrooms);
    _fetchChatrooms();
  }

  @override
  void dispose() {
    widget.tempRefresh.removeListener(_fetchChatrooms);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatrooms() async {
    setState(() => _chatrooms = null);

    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;

    if (uid.isEmpty) {
      return;
    }

    final result = await api.getChatrooms(uid);

    if (!mounted) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    if (!loggedIn) {
      return DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Log in to create relationships'),
                ElevatedButton(
                  onPressed: () => context.pushNamed('signup'),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
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
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
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
                        FocusScope.of(context).unfocus();
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        TabBar(
          indicatorColor: Theme.of(context).primaryColor,
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text('Friends'),
            ),
            Tab(
              child: Text('Invites'),
            ),
          ],
        ),
        if (_filterString.isEmpty)
          Visibility(
            visible: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: _collections.length,
                  itemBuilder: (context, index) {
                    final collection = _collections[index];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 82,
                          height: 110,
                          clipBehavior: Clip.hardEdge,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  const Color.fromRGBO(0xFF, 0x5F, 0x5F, 1.0),
                              width: 2,
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(11)),
                          ),
                          margin: const EdgeInsets.all(9),
                          child: Image.network(
                            collection.photos.first.url,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 82,
                          child: Text(
                            'Name',
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
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
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              Builder(
                builder: (context) {
                  final filteredChatrooms = _chatrooms?.where((c) => c
                      .profile.name
                      .toLowerCase()
                      .contains(_filterString.toLowerCase()));
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _ConversationList(
                        chatrooms: filteredChatrooms
                            ?.where((chatroom) =>
                                chatroom.state == ChatroomState.accepted)
                            .toList(),
                        emptyLabel:
                            'Invite someone to chat,\nthen continue the conversation here',
                        filtered: _filterString.isNotEmpty,
                        onRefresh: _fetchChatrooms,
                        onOpen: _openChat,
                      ),
                      _ConversationList(
                        chatrooms: filteredChatrooms
                            ?.where((chatroom) =>
                                chatroom.state == ChatroomState.invitation)
                            .toList(),
                        emptyLabel: 'You have no pending invites',
                        filtered: _filterString.isNotEmpty,
                        onRefresh: _fetchChatrooms,
                        onOpen: _openChat,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openChat(Chatroom chatroom) {
    FocusScope.of(context).unfocus();

    if (chatroom.state == ChatroomState.accepted) {
      context.pushNamed(
        'chat',
        params: {'uid': chatroom.profile.uid},
        extra: ChatPageArguments(
          otherUid: chatroom.profile.uid,
          otherProfile: chatroom.profile,
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

    final index = _chatrooms?.indexOf(chatroom);
    if (index != null && index != -1) {
      setState(() => _chatrooms?[index] = chatroom.copyWith(unreadCount: 0));
    }
  }
}

class _ConversationList extends StatelessWidget {
  final List<Chatroom>? chatrooms;
  final String emptyLabel;
  final bool filtered;
  final Future<void> Function() onRefresh;
  final void Function(Chatroom chatroom) onOpen;

  const _ConversationList({
    Key? key,
    required this.chatrooms,
    required this.emptyLabel,
    required this.filtered,
    required this.onRefresh,
    required this.onOpen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatrooms = this.chatrooms;
    if (chatrooms == null) {
      return const SafeArea(
        child: Center(
          child: LoadingIndicator(),
        ),
      );
    }

    if (chatrooms.isEmpty) {
      return SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                filtered ? 'No results' : emptyLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!filtered)
                ElevatedButton(
                  onPressed: onRefresh,
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

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: chatrooms.length,
        separatorBuilder: (_, index) {
          final suggestedFriendDivider = index == chatrooms.length;
          return Divider(
            color: suggestedFriendDivider
                ? const Color.fromRGBO(0x99, 0x91, 0x91, 1.0)
                : const Color.fromRGBO(0x16, 0x16, 0x16, 1.0),
            height: suggestedFriendDivider ? 3 : 1,
            indent: 29,
          );
        },
        itemBuilder: (context, index) {
          const suggestedFriend = false;
          final chatroom = chatrooms[index];
          return Stack(
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
                      child: Button(
                        onPressed: () {
                          context.pushNamed(
                            'view_collection',
                            extra: ViewCollectionPageArguments.profile(
                              profile: chatroom.profile,
                            ),
                          );
                        },
                        child: Image.network(
                          chatroom.profile.photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Button(
                        onPressed: () => onOpen(chatroom),
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
          );
        },
      ),
    );
  }
}
