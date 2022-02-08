import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/call_screen.dart';
import 'package:openup/chat_screen.dart';
import 'package:openup/public_profile_screen.dart';
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

    final api = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    api.getConnections(uid).then((connections) {
      if (mounted) {
        setState(() => _connections = connections);
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
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
                'connections',
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
                    child: Text(
                      'No Connections',
                      style: Theming.of(context).text.body,
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 20, bottom: 64),
                  itemCount: filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection = filteredConnections[index];
                    final profile = connection.profile;
                    final usersApi = ref.read(usersApiProvider);
                    final countStream = usersApi.unreadChatMessageCountsStream
                        .map((event) => event[profile.uid] ?? 0);
                    return StreamBuilder<int>(
                      stream: countStream,
                      initialData: 0,
                      builder: (context, snapshot) {
                        final count = snapshot.requireData;
                        return ConnectionTile(
                          onPressed: () => setState(() =>
                              _openIndex = _openIndex == index ? -1 : index),
                          profile: profile,
                          unreadCount: count,
                          expanded: _openIndex == index,
                          onShowProfile: () {
                            Navigator.of(context).pushNamed(
                              'public-profile',
                              arguments: PublicProfileArguments(
                                publicProfile: profile,
                                editable: false,
                              ),
                            );
                          },
                          onChat: () {
                            usersApi.updateUnreadChatMessagesCount(
                              profile.uid,
                              0,
                            );
                            Navigator.of(context).pushNamed(
                              'chat',
                              arguments: ChatArguments(
                                profile: profile,
                                chatroomId: connection.chatroomId,
                              ),
                            );
                          },
                          onCall: () => _onCall(profile, video: false),
                          onVideoCall: () => _onCall(profile, video: true),
                        );
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
                            onPressed: () {
                              setState(() {
                                FocusScope.of(context).unfocus();
                                _search = null;
                                _showSearchBox = false;
                              });
                            },
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

  void _onCall(PublicProfile profile, {required bool video}) async {
    final api = ref.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    final rid = await api.call(uid, profile.uid, video);
    if (mounted) {
      final route = video ? 'friends-video-call' : 'friends-voice-call';
      Navigator.of(context).pushNamed(
        route,
        arguments: CallPageArguments(
          rid: rid,
          profiles: [profile],
          rekindles: [],
          serious: false,
        ),
      );
    }
  }
}

class ConnectionTile extends StatefulWidget {
  final VoidCallback? onPressed;
  final PublicProfile profile;
  final int unreadCount;
  final bool expanded;
  final VoidCallback onShowProfile;
  final VoidCallback onChat;
  final VoidCallback onCall;
  final VoidCallback onVideoCall;

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
                        color: Colors.blue,
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
