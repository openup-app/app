import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/profile_screen.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/unread_message_badge.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<Connection>? _connections;
  int _openIndex = -1;

  String? _search;
  bool _showSearchBox = false;
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _reloadConnections();
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _reloadConnections() async {
    setState(() => _connections = null);
    final uid = ref.read(userProvider).uid;
    final api = GetIt.instance.get<Api>();
    final result = await api.getConnections(uid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        setState(() {
          _connections = r;
          _showSearchBox = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final connections = _connections;
    final search = _search?.trim().toLowerCase();
    final filteredConnections = search == null
        ? connections
        : connections
            ?.where((c) => c.profile.name.trim().toLowerCase().contains(search))
            .toList();

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).padding.left,
            top: MediaQuery.of(context).padding.top + 16,
            child: const BackIconButton(),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).padding.top + 28),
              child: Text(
                'friends',
                style: Theming.of(context).text.bodySecondary,
              ),
            ),
          ),
          Container(
            margin:
                EdgeInsets.only(top: MediaQuery.of(context).padding.top + 64),
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(0xFF, 0x3A, 0x35, 0x35),
                  Color.fromARGB(0xFF, 0xFF52, 0x3A, 0x3A),
                ],
              ),
            ),
            child: Builder(
              builder: (context) {
                if (filteredConnections == null) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (filteredConnections.isEmpty) {
                  return Center(
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(maxWidth: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Your friends will show up here when you have added each other',
                        textAlign: TextAlign.center,
                        style: Theming.of(context).text.body,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 64),
                  itemCount: filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection = filteredConnections[index];
                    final profile = connection.profile;
                    final unreadMessageCount = ref.watch(
                        userProvider.select((p) => p.unreadMessageCount));
                    final count = unreadMessageCount[profile.uid] ?? 0;
                    return ConnectionTile(
                      onPressed: () => setState(
                          () => _openIndex = _openIndex == index ? -1 : index),
                      profile: profile,
                      unreadCount: count,
                      expanded: _openIndex == index,
                      onShowProfile: () {
                        Navigator.of(context).pushNamed(
                          'profile',
                          arguments: ProfileArguments(
                            profile: profile,
                            editable: false,
                          ),
                        );
                      },
                      onChat: () {
                        final unreadMessageCount =
                            Map.of(ref.read(userProvider).unreadMessageCount);
                        unreadMessageCount[profile.uid] = 0;
                        ref
                            .read(userProvider.notifier)
                            .unreadMessageCount(unreadMessageCount);
                        Navigator.of(context).pushNamed(
                          'chat',
                          arguments: ChatArguments(
                            uid: profile.uid,
                            chatroomId: connection.chatroomId,
                          ),
                        );
                      },
                      onCall: () => _onCall(profile, video: false),
                      onVideoCall: () => _onCall(profile, video: true),
                      onDeleteConnection: () async {
                        final connections = await showDialog<List<Connection>>(
                          context: context,
                          builder: (context) {
                            return RemoveConnectionAlertDialog(
                              uid: ref.read(userProvider).uid,
                              profile: profile,
                            );
                          },
                        );

                        if (mounted && connections != null) {
                          _dismissSearch();
                          setState(() => _connections = connections);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            left: _showSearchBox ? 16 : null,
            right: 16,
            bottom: 16,
            child: Builder(builder: (context) {
              final textStyle = Theming.of(context)
                  .text
                  .body
                  .copyWith(fontWeight: FontWeight.w500, fontSize: 20);
              final dropShadow = BoxShadow(
                color: Theming.of(context).shadow,
                offset: const Offset(0, 4),
                blurRadius: 2.0,
              );
              if (_showSearchBox) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    boxShadow: [dropShadow],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(0xFF, 0xF2, 0xC5, 0xC5),
                            blurRadius: 0,
                          ),
                          BoxShadow(
                            color: Color.fromARGB(0xFF, 0xE2, 0x55, 0x55),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: textStyle,
                              focusNode: _searchFocusNode,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (text) =>
                                  setState(() => _search = text),
                              decoration: InputDecoration(
                                icon: const Icon(
                                  Icons.person_search,
                                  color: Colors.white,
                                ),
                                border: InputBorder.none,
                                hintText: 'Search',
                                hintStyle: textStyle,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _dismissSearch,
                            child: Text('Done',
                                style: Theming.of(context).text.button),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return Button(
                onPressed: _connections == null
                    ? null
                    : () {
                        setState(() => _showSearchBox = true);
                        _searchFocusNode.requestFocus();
                      },
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    boxShadow: [dropShadow],
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    color: const Color.fromARGB(0xFF, 0xE2, 0x55, 0x55),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_search),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: textStyle,
                      ),
                    ],
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
  }

  void _dismissSearch() {
    setState(() {
      FocusScope.of(context).unfocus();
      _search = null;
      _showSearchBox = false;
    });
  }

  void _onCall(
    Profile profile, {
    required bool video,
  }) async {
    final purpose = Purpose.friends.name;
    final route = video ? '$purpose-video-call' : '$purpose-voice-call';
    final api = GetIt.instance.get<Api>();
    final result = await api.call(
      profile.uid,
      video,
      group: false,
    );
    if (mounted) {
      result.fold((l) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to call ${profile.name}'),
          ),
        );
      }, (rid) {
        Navigator.of(context).pushNamed(
          route,
          arguments: CallPageArguments(
            rid: rid,
            profiles: [profile.toSimpleProfile()],
            rekindles: [],
            serious: false,
          ),
        );
      });
    }
  }
}

class ConnectionTile extends StatefulWidget {
  final VoidCallback? onPressed;
  final Profile profile;
  final int unreadCount;
  final bool expanded;
  final VoidCallback onShowProfile;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final VoidCallback onDeleteConnection;

  const ConnectionTile({
    Key? key,
    required this.onPressed,
    required this.profile,
    required this.unreadCount,
    required this.expanded,
    required this.onShowProfile,
    required this.onChat,
    required this.onCall,
    required this.onVideoCall,
    required this.onDeleteConnection,
  }) : super(key: key);

  @override
  State<ConnectionTile> createState() => _ConnectionTileState();
}

class _ConnectionTileState extends State<ConnectionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _chatButtonKey = GlobalKey();
  final _profileIconKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  void didUpdateWidget(covariant ConnectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) {
      if (widget.expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileIconOffset =
        ((_profileIconKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero);
    final chatButtonOffset =
        ((_chatButtonKey.currentContext?.findRenderObject() as RenderBox?)
                ?.localToGlobal(Offset.zero) ??
            Offset.zero);

    return Stack(
      children: [
        Column(
          children: [
            Button(
              onPressed: widget.onPressed,
              child: SizedBox(
                height: 96,
                child: Row(
                  children: [
                    const SizedBox(width: 32),
                    Container(
                      width: 42,
                      height: 56,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(8),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Theming.of(context).shadow,
                            offset: const Offset(0, 4),
                            blurRadius: 2.0,
                          ),
                        ],
                      ),
                      child: ProfilePhoto(
                        key: _profileIconKey,
                        url: widget.profile.photo,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.profile.name,
                      style: Theming.of(context).text.subheading,
                    ),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: CurvedAnimation(
                parent: _controller,
                curve: Curves.easeIn,
              ),
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: Curves.easeIn,
                ),
                child: Container(
                  height: 54,
                  margin: const EdgeInsets.only(
                    left: 92,
                    right: 16,
                    bottom: 8,
                    top: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    color: const Color.fromARGB(0xFF, 0x77, 0x77, 0x77),
                    boxShadow: [
                      BoxShadow(
                        color: Theming.of(context).shadow,
                        offset: const Offset(0, 4),
                        blurRadius: 2.0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Button(
                        onPressed: widget.onShowProfile,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.account_circle,
                          ),
                        ),
                      ),
                      Button(
                        onPressed: widget.onCall,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.phone,
                          ),
                        ),
                      ),
                      Button(
                        onPressed: widget.onChat,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.message,
                            key: _chatButtonKey,
                          ),
                        ),
                      ),
                      Button(
                        onPressed: widget.onVideoCall,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.videocam_sharp,
                          ),
                        ),
                      ),
                      Button(
                        onPressed: widget.onDeleteConnection,
                        child: const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Icon(
                            Icons.person_remove,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.unreadCount != 0)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: widget.expanded
                ? chatButtonOffset.dx + 12
                : profileIconOffset.dx + 28,
            top: widget.expanded ? 104 : 0,
            width: widget.expanded ? 22 : 32,
            height: widget.expanded ? 22 : 32,
            child: UnreadMessageBadge(
              count: widget.unreadCount,
            ),
          ),
      ],
    );
  }
}

class RemoveConnectionAlertDialog extends StatefulWidget {
  final String uid;
  final Profile profile;
  const RemoveConnectionAlertDialog({
    Key? key,
    required this.uid,
    required this.profile,
  }) : super(key: key);

  @override
  _RemoveConnectionAlertDialogState createState() =>
      _RemoveConnectionAlertDialogState();
}

class _RemoveConnectionAlertDialogState
    extends State<RemoveConnectionAlertDialog> {
  bool _deleting = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Remove connection with ${widget.profile.name}?'),
      actions: [
        TextButton(
          onPressed: () async {
            setState(() => _deleting = true);
            final api = GetIt.instance.get<Api>();
            final result =
                await api.deleteConnection(widget.uid, widget.profile.uid);
            result.fold(
              (l) {
                displayError(context, l);
                Navigator.of(context).pop();
              },
              (r) => Navigator.of(context).pop(r),
            );
          },
          child: _deleting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Text(
                  'Remove',
                  style: Theming.of(context).text.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.red),
                ),
        ),
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text(
            'Cancel',
            style: Theming.of(context).text.body.copyWith(
                fontSize: 14, fontWeight: FontWeight.w300, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
