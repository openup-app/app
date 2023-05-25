import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/view_profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage>
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
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

        return ActivePage(
          onActivate: () {
            /// Notifications don't update chats, so refreshe on page activation
            ref.read(userProvider2.notifier).refreshChatrooms();
          },
          onDeactivate: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.only(top: 30.0, left: 20),
                child: Hero(
                  tag: 'conversations_title',
                  child: Text(
                    'Conversations',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 32, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              Container(
                height: 31,
                margin: const EdgeInsets.only(
                  left: 16,
                  top: 8,
                  right: 16,
                  bottom: 16,
                ),
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 26,
                      color: Color.fromRGBO(0x00, 0x00, 0x00, 0.05),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 11, right: 6),
                        child: TextFormField(
                          controller: _searchController,
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            icon: const Icon(
                              Icons.search,
                              size: 16,
                            ),
                            hintText: 'Search',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color.fromRGBO(
                                      0x8D, 0x8D, 0x8D, 1.0),
                                ),
                          ),
                        ),
                      ),
                    ),
                    if (_filterString.isNotEmpty)
                      Button(
                        onPressed: () {
                          setState(() => _searchController.text = "");
                          FocusScope.of(context).unfocus();
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.black,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
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
                                    color: const Color.fromRGBO(
                                        0xFF, 0x5F, 0x5F, 1.0),
                                    width: 2,
                                  ),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(11)),
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
                child: Consumer(
                  builder: (context, ref, child) {
                    final filteredChatrooms =
                        ref.watch(userProvider2.select((p) {
                      return p.map(
                        guest: (_) => null,
                        signedIn: (signedIn) => signedIn.chatrooms?.where((c) {
                          return c.profile.name
                              .toLowerCase()
                              .contains(_filterString.toLowerCase());
                        }),
                      );
                    }));

                    final nonPendingChatrooms = filteredChatrooms
                        ?.where((chatroom) =>
                            chatroom.inviteState != ChatroomState.pending)
                        .toList();
                    return _ConversationList(
                      chatrooms: nonPendingChatrooms,
                      emptyLabel:
                          'Invite someone to chat,\nthen continue the conversation here',
                      filtered: _filterString.isNotEmpty,
                      onRefresh:
                          ref.read(userProvider2.notifier).refreshChatrooms,
                      onOpen: _openChat,
                      onDelete: (index) =>
                          _deleteChatroom(nonPendingChatrooms![index].profile),
                    );
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).viewInsets.bottom,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChat(Chatroom chatroom) {
    FocusScope.of(context).unfocus();
    context.pushNamed(
      'chat',
      params: {'uid': chatroom.profile.uid},
      extra: ChatPageArguments(chatroom: chatroom),
    );
    final index = _chatrooms?.indexOf(chatroom);
    if (index != null && index != -1) {
      setState(() => _chatrooms?[index] = chatroom.copyWith(unreadCount: 0));
    }
  }

  void _deleteChatroom(Profile profile) async {
    await withBlockingModal(
      context: context,
      label: 'Removing friend',
      future: ref.read(userProvider2.notifier).deleteChatroom(profile.uid),
    );
  }
}

class _ConversationList extends StatelessWidget {
  final List<Chatroom>? chatrooms;
  final String emptyLabel;
  final bool filtered;
  final Future<void> Function() onRefresh;
  final void Function(Chatroom chatroom) onOpen;
  final void Function(int index) onDelete;

  const _ConversationList({
    Key? key,
    required this.chatrooms,
    required this.emptyLabel,
    required this.filtered,
    required this.onRefresh,
    required this.onOpen,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatrooms = this.chatrooms;
    if (chatrooms == null) {
      return const Center(
        child: LoadingIndicator(),
      );
    }

    if (chatrooms.isEmpty) {
      return Center(
        child: Text(
          filtered ? 'No results' : emptyLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: const Color.fromRGBO(0x70, 0x70, 0x70, 1.0),
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
          return const Divider(
            color: Color.fromRGBO(0xDA, 0xDA, 0xDA, 1.0),
            height: 1,
            indent: 29,
          );
        },
        itemBuilder: (context, index) {
          final chatroom = chatrooms[index];
          return LayoutBuilder(
            builder: (context, constraints) {
              final actionPaneExtentRatio = 80 / constraints.maxWidth;
              return SizedBox(
                height: 84,
                child: Slidable(
                  key: Key(chatroom.profile.uid),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: actionPaneExtentRatio,
                    children: [
                      SlidableAction(
                        onPressed: (context) {
                          _showDeleteConversationConfirmationModal(
                            context: context,
                            profile: chatroom.profile,
                            index: index,
                          );
                        },
                        backgroundColor:
                            const Color.fromRGBO(0xFF, 0x07, 0x07, 1.0),
                        icon: Icons.delete,
                      ),
                    ],
                  ),
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
                                              Color.fromRGBO(
                                                  0xF6, 0x28, 0x28, 1.0),
                                              Color.fromRGBO(
                                                  0xFF, 0x5F, 0x5F, 1.0),
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
                                    'view_profile',
                                    extra: ViewProfilePageArguments.profile(
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
                                      _formatRelativeDate(chatroom.lastUpdated),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 14,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    if (chatroom.inviteState !=
                                        ChatroomState.accepted)
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
                            UnreadIndicator(
                              count: chatroom.unreadCount,
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
                      Positioned(
                        left: 44,
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
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConversationConfirmationModal({
    required BuildContext context,
    required Profile profile,
    required int index,
  }) async {
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text(
              'Remove ${profile.name} as a friend and delete this conversation?'),
          cancelButton: CupertinoActionSheetAction(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Remove friend and delete'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      onDelete(index);
    }
  }
}

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.isNegative) {
    return 'now';
  }

  final localDate = date.toLocal();
  final yesterday = DateUtils.dateOnly(now).subtract(const Duration(days: 1));
  if (DateUtils.isSameDay(localDate, now)) {
    final twentyFourHourMinuteFormat = DateFormat.Hm();
    return twentyFourHourMinuteFormat.format(localDate);
  } else if (DateUtils.isSameDay(localDate, yesterday)) {
    return 'yesterday';
  } else if (diff.inDays < 7) {
    final dayNameFormat = DateFormat.EEEE();
    return dayNameFormat.format(localDate);
  } else if (localDate.year == now.year) {
    final shortDateFormat = DateFormat.MMMMd();
    return shortDateFormat.format(localDate);
  } else {
    final longDateFormat = DateFormat.yMMMMd();
    return longDateFormat.format(localDate);
  }
}
