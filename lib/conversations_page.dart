import 'dart:math';

import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/animation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/chat_page.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ConversationsPage extends ConsumerStatefulWidget {
  const ConversationsPage({super.key});

  @override
  ConsumerState<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends ConsumerState<ConversationsPage> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OpenupAppBar(
        body: const OpenupAppBarBody(
          center: Text('Messages'),
        ),
        toolbar: Padding(
          padding: const EdgeInsets.only(
            top: 4,
            left: 11,
            right: 11,
          ),
          child: _SearchField(
            onSearchChanged: (value) => setState(() => _filter = value),
          ),
        ),
        blurBackground: false,
      ),
      body: Builder(
        builder: (context) {
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
          return _ConversationsPageContents(
            filter: _filter,
          );
        },
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;

  const _SearchField({
    super.key,
    required this.onSearchChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      widget.onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(6)),
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
                    color: Color.fromRGBO(0x3B, 0x3B, 0x3B, 1.0),
                  ),
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: Color.fromRGBO(0x3B, 0x3B, 0x3B, 1.0),
                  ),
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            Button(
              onPressed: () {
                setState(() => _searchController.clear());
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
    );
  }
}

class _ConversationsPageContents extends ConsumerStatefulWidget {
  final String filter;

  const _ConversationsPageContents({
    Key? key,
    this.filter = '',
  }) : super(key: key);

  @override
  ConsumerState<_ConversationsPageContents> createState() =>
      _ConversationsPageContentsState();
}

class _ConversationsPageContentsState
    extends ConsumerState<_ConversationsPageContents>
    with SingleTickerProviderStateMixin {
  final _collections = <Collection>[];

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () {
        /// Notifications don't update chats, so refreshe on page activation
        ref.read(userProvider.notifier).refreshChatrooms();
      },
      onDeactivate: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Expanded(
            child: Column(
              children: [
                if (widget.filter.isEmpty)
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
                          ref.watch(userProvider.select((p) {
                        return p.map(
                          guest: (_) => null,
                          signedIn: (signedIn) =>
                              signedIn.chatrooms?.where((c) {
                            return c.profile.profile.name
                                .toLowerCase()
                                .contains(widget.filter.toLowerCase());
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
                        filtered: widget.filter.isNotEmpty,
                        onRefresh:
                            ref.read(userProvider.notifier).refreshChatrooms,
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
    ref.read(userProvider.notifier).openChatroom(chatroom.profile.profile.uid);
  }

  void _deleteChatroom(Profile profile) async {
    await withBlockingModal(
      context: context,
      label: 'Removing friend',
      future: ref.read(userProvider.notifier).deleteChatroom(profile.uid),
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
            color: Colors.white,
          );
        },
      ),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85 / 1,
        ),
        padding: const EdgeInsets.all(5),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: chatrooms.length,
        itemBuilder: (context, index) {
          final chatroom = chatrooms[index];
          return Stack(
            key: Key(chatroom.profile.profile.uid),
            children: [
              WiggleBuilder(
                seed: chatroom.profile.profile.uid.hashCode,
                builder: (context, child, wiggle) {
                  final offset = Offset(
                    wiggle(frequency: 0.3, amplitude: 20),
                    wiggle(frequency: 0.3, amplitude: 20),
                  );

                  final rotationZ =
                      wiggle(frequency: 0.5, amplitude: radians(4));
                  final rotationY =
                      wiggle(frequency: 0.5, amplitude: radians(10));
                  const perspectiveDivide = 0.002;
                  final transform = Matrix4.identity()
                    ..setEntry(3, 2, perspectiveDivide)
                    ..rotateY(rotationY)
                    ..rotateZ(rotationZ);
                  return Transform.translate(
                    offset: offset,
                    child: Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
                child: Button(
                  onPressed: () => onOpen(chatroom),
                  onLongPressStart: () async {
                    final shouldDelete =
                        await _showDeleteConversationConfirmationModal(
                      context: context,
                      name: chatroom.profile.profile.name,
                    );
                    if (context.mounted && shouldDelete) {
                      onDelete(index);
                    }
                  },
                  child: Container(
                    height: 200,
                    margin: EdgeInsets.only(
                      left: index.isEven ? 6 : 10,
                      top: 8,
                      right: index.isEven ? 10 : 6,
                      bottom: 8,
                    ),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                      color: Colors.white,
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: AspectRatio(
                            aspectRatio: 1 / 1,
                            child: Image.network(
                              chatroom.profile.profile.photo,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Text(
                          chatroom.profile.profile.name.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Covered By Your Grace',
                            fontWeight: FontWeight.w400,
                            fontSize: 22,
                            color: Color.fromRGBO(0x29, 0x29, 0x29, 1.0),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                    ),
                  ),
                ),
              ),
              if (chatroom.unreadCount != 0)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 27,
                    height: 27,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.fromRGBO(0xFF, 0x16, 0x16, 1.0),
                        boxShadow: [
                          BoxShadow(
                            offset: Offset(0, 4),
                            blurRadius: 4,
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                          )
                        ]),
                    child: Center(
                      child: Text(
                        chatroom.unreadCount > 9
                            ? '9+'
                            : chatroom.unreadCount.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _showDeleteConversationConfirmationModal({
    required BuildContext context,
    required String name,
  }) async {
    final result = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text('Remove $name as a friend and delete this conversation?'),
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

    return result == true;
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
