import 'dart:math';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/shell_page.dart';
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
    final loggedIn = ref.watch(authProvider.select((p) {
      return p.map(
        guest: (_) => false,
        signedIn: (_) => true,
      );
    }));
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
          SizedBox(
            height: MediaQuery.of(context).padding.top + 40,
          ),
          Container(
            height: 32,
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
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 11, right: 6),
                    child: TextFormField(
                      controller: _searchController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search,
                          size: 18,
                        ),
                        hintText: 'Search',
                        hintStyle: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
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
          const SizedBox(height: 4),
          const Divider(
            height: 1,
            color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
          ),
          Expanded(
            child: Column(
              children: [
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
                          signedIn: (signedIn) =>
                              signedIn.chatrooms?.where((c) {
                            return c.profile.profile.name
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
                        onDelete: (index) => _deleteChatroom(
                            nonPendingChatrooms![index].profile.profile),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openChat(Chatroom chatroom) {
    FocusScope.of(context).unfocus();
    context.pushNamed(
      'chat',
      params: {'uid': chatroom.profile.profile.uid},
      extra: ChatPageArguments(chatroom: chatroom),
    );
    ref.read(userProvider2.notifier).openChatroom(chatroom.profile.profile.uid);
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

    return CustomRefreshIndicator(
      onRefresh: onRefresh,
      builder: _SimpleIndicatorDelegate(
        builder: (context, controller) {
          return const LoadingIndicator(
            color: Colors.black,
          );
        },
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actionPaneExtentRatio = 80 / constraints.maxWidth;
          return ListView.builder(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: chatrooms.length,
            itemBuilder: (context, index) {
              final chatroom = chatrooms[index];
              return SizedBox(
                height: 80,
                child: Column(
                  children: [
                    Expanded(
                      child: Slidable(
                        key: Key(chatroom.profile.profile.uid),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: actionPaneExtentRatio,
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _showDeleteConversationConfirmationModal(
                                  context: context,
                                  profile: chatroom.profile.profile,
                                  index: index,
                                );
                              },
                              backgroundColor:
                                  const Color.fromRGBO(0xFF, 0x07, 0x07, 1.0),
                              icon: Icons.delete,
                            ),
                          ],
                        ),
                        child: Button(
                          onPressed: () => onOpen(chatroom),
                          child: SizedBox(
                            height: 140,
                            child: Row(
                              children: [
                                Visibility(
                                  visible: chatroom.unreadCount != 0,
                                  maintainSize: true,
                                  maintainState: true,
                                  maintainAnimation: true,
                                  child: SizedBox(
                                    width: 33,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Color.fromRGBO(
                                                0x00, 0x94, 0xFF, 1.0),
                                            Color.fromRGBO(
                                                0x64, 0xBC, 0xFC, 1.0),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 47,
                                  height: 47,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.network(
                                    chatroom.profile.profile.photo,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      OnlineIndicatorBuilder(
                                        uid: chatroom.profile.profile.uid,
                                        builder: (context, online) {
                                          final hasSubtitle =
                                              chatroom.inviteState !=
                                                      ChatroomState.accepted ||
                                                  online ||
                                                  chatroom.unreadCount != 0;
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (hasSubtitle)
                                                const SizedBox(height: 16),
                                              Text(
                                                chatroom.profile.profile.name,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (hasSubtitle)
                                                const SizedBox(height: 4),
                                              if (chatroom.inviteState !=
                                                  ChatroomState.accepted)
                                                const Text(
                                                  'New chat invitation',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12,
                                                    color: Color.fromRGBO(
                                                        0x00, 0x94, 0xFF, 1.0),
                                                  ),
                                                )
                                              else if (online)
                                                const Text(
                                                  'online',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12,
                                                    color: Color.fromRGBO(
                                                        0x94, 0x94, 0x94, 1.0),
                                                  ),
                                                )
                                              else if (chatroom.unreadCount !=
                                                  0)
                                                const Text(
                                                  'New message',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 12,
                                                    color: Color.fromRGBO(
                                                        0x00, 0x94, 0xFF, 1.0),
                                                  ),
                                                ),
                                            ],
                                          );
                                        },
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 3.0),
                                          child: Text(
                                            _formatRelativeDate(
                                                chatroom.lastUpdated),
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SvgPicture.asset(
                                  'assets/images/chevron_right.svg',
                                  height: 12,
                                ),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      color: Color.fromRGBO(0xDA, 0xDA, 0xDA, 1.0),
                      height: 1,
                      indent: 29,
                    ),
                  ],
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
    final timeFormat = DateFormat.jm();
    return timeFormat.format(localDate);
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

/// Modified from package:custom_refresh_indicator material_indicator_delegate.dart
class _SimpleIndicatorDelegate extends IndicatorBuilderDelegate {
  final Widget Function(BuildContext context, IndicatorController controller)
      builder;

  const _SimpleIndicatorDelegate({
    required this.builder,
  });

  @override
  Widget build(
    BuildContext context,
    Widget child,
    IndicatorController controller,
  ) {
    return Stack(
      children: <Widget>[
        child,
        _PositionedIndicatorContainer(
          edgeOffset: 0,
          displacement: 0,
          controller: controller,
          child: Transform.scale(
            scale: controller.isFinalizing
                ? controller.value.clamp(0.0, 1.0)
                : 1.0,
            child: Container(
              width: 41,
              height: 41,
              margin: const EdgeInsets.all(4.0),
              child: _InfiniteRotation(
                running: controller.isLoading,
                child: builder(context, controller),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get autoRebuild => true;
}

/// Copied from package:custom_refresh_indicator material_indicator_delegate.dart
class _PositionedIndicatorContainer extends StatelessWidget {
  final IndicatorController controller;
  final double displacement;
  final Widget child;
  final double edgeOffset;

  const _PositionedIndicatorContainer({
    Key? key,
    required this.child,
    required this.controller,
    required this.displacement,
    required this.edgeOffset,
  }) : super(key: key);

  Alignment _getAlignement(IndicatorSide side) {
    switch (side) {
      case IndicatorSide.left:
        return Alignment.centerLeft;
      case IndicatorSide.top:
        return Alignment.topCenter;
      case IndicatorSide.right:
        return Alignment.centerRight;
      case IndicatorSide.bottom:
        return Alignment.bottomCenter;
      case IndicatorSide.none:
        throw UnsupportedError('Cannot get alignement for "none" side.');
    }
  }

  EdgeInsets _getEdgeInsets(IndicatorSide side) {
    switch (side) {
      case IndicatorSide.left:
        return EdgeInsets.only(left: displacement);
      case IndicatorSide.top:
        return EdgeInsets.only(top: displacement);
      case IndicatorSide.right:
        return EdgeInsets.only(right: displacement);
      case IndicatorSide.bottom:
        return EdgeInsets.only(bottom: displacement);
      case IndicatorSide.none:
        throw UnsupportedError('Cannot get edge insets for "none" side.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.side.isNone) return const SizedBox();

    final isVerticalAxis = controller.side.isTop || controller.side.isBottom;
    final isHorizontalAxis = controller.side.isLeft || controller.side.isRight;

    final AlignmentDirectional alignment = isVerticalAxis
        ? AlignmentDirectional(-1.0, controller.side.isTop ? 1.0 : -1.0)
        : AlignmentDirectional(controller.side.isLeft ? 1.0 : -1.0, -1.0);

    final double value = controller.isFinalizing ? 1.0 : controller.value;

    return Positioned(
      top: isHorizontalAxis
          ? 0
          : controller.side.isTop
              ? edgeOffset
              : null,
      bottom: isHorizontalAxis
          ? 0
          : controller.side.isBottom
              ? edgeOffset
              : null,
      left: isVerticalAxis
          ? 0
          : controller.side.isLeft
              ? edgeOffset
              : null,
      right: isVerticalAxis
          ? 0
          : controller.side.isRight
              ? edgeOffset
              : null,
      child: ClipRRect(
        child: Align(
          alignment: alignment,
          heightFactor: isVerticalAxis ? max(value, 0.0) : null,
          widthFactor: isHorizontalAxis ? max(value, 0.0) : null,
          child: Container(
            padding: _getEdgeInsets(controller.side),
            alignment: _getAlignement(controller.side),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Copied from package:custom_refresh_indicator material_indicator_delegate.dart
class _InfiniteRotation extends StatefulWidget {
  final Widget? child;
  final bool running;

  const _InfiniteRotation({
    required this.child,
    required this.running,
    Key? key,
  }) : super(key: key);
  @override
  _InfiniteRotationState createState() => _InfiniteRotationState();
}

class _InfiniteRotationState extends State<_InfiniteRotation>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void didUpdateWidget(_InfiniteRotation oldWidget) {
    if (oldWidget.running != widget.running) {
      if (widget.running) {
        _startAnimation();
      } else {
        _rotationController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 50),
        );
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 750),
      vsync: this,
    );

    if (widget.running) {
      _startAnimation();
    }

    super.initState();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _rotationController.repeat();
  }

  @override
  Widget build(BuildContext context) =>
      RotationTransition(turns: _rotationController, child: widget.child);
}
