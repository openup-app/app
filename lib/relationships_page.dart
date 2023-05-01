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
import 'package:openup/widgets/section.dart';

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
  String _filterString = '';

  final _collections = <Collection>[];
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
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Log in start conversations'),
          ElevatedButton(
            onPressed: () => context.pushNamed('signup'),
            child: const Text('Log in'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 31,
          margin: EdgeInsets.only(
            left: 16,
            top: 24 + MediaQuery.of(context).padding.top,
            right: 16,
            bottom: 16,
          ),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(7),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 26,
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.05),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11, right: 6.0),
                    child: TextFormField(
                      controller: _searchController,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Search',
                        hintStyle: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color:
                                  const Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
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
        const SectionTitle(
          title: Text('MESSAGES'),
        ),
        Expanded(
          child: ColoredBox(
            color: Colors.white,
            child: Builder(
              builder: (context) {
                final filteredChatrooms = _chatrooms?.where((c) => c
                    .profile.name
                    .toLowerCase()
                    .contains(_filterString.toLowerCase()));

                return _ConversationList(
                  chatrooms: filteredChatrooms
                      ?.where((chatroom) =>
                          chatroom.state == ChatroomState.accepted)
                      .toList(),
                  emptyLabel:
                      'Invite someone to chat,\nthen continue the conversation here',
                  filtered: _filterString.isNotEmpty,
                  onRefresh: _fetchChatrooms,
                  onOpen: _openChat,
                );
              },
            ),
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
        // Scrollable to use PrimaryScrollController to dismiss draggable sheet
        child: SingleChildScrollView(
          child: Center(
            child: LoadingIndicator(),
          ),
        ),
      );
    }

    if (chatrooms.isEmpty) {
      return SafeArea(
        // Scrollable to use PrimaryScrollController to dismiss draggable sheet
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  filtered ? 'No results' : emptyLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 18, fontWeight: FontWeight.w400),
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
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: chatrooms.length,
      separatorBuilder: (_, index) {
        return const Divider(
          color: Color.fromRGBO(0xDA, 0xDA, 0xDA, 1.0),
          height: 1,
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
                    width: 63,
                    height: 63,
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
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
                          Text(chatroom.profile.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400)),
                          const SizedBox(height: 2),
                          Text(
                            'yesterday',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: const Color.fromRGBO(
                                        0x70, 0x70, 0x70, 1.0)),
                          ),
                          const SizedBox(height: 2),
                          if (chatroom.state == ChatroomState.pending)
                            Text(
                              'New chat invitation',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: const Color.fromRGBO(
                                          0xFF, 0x00, 0x00, 1.0)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color.fromRGBO(0xBA, 0xBA, 0xBA, 1.0),
                    size: 26,
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
    );
  }
}
