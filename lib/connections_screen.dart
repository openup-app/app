import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';

class ConnectionsScreen extends ConsumerStatefulWidget {
  const ConnectionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConnectionsScreen> createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends ConsumerState<ConnectionsScreen> {
  List<PublicProfile>? _connections;
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
            ?.where(
                (profile) => profile.name.trim().toLowerCase().contains(search))
            .toList();

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).padding.left,
            top: MediaQuery.of(context).padding.top + 16,
            child: const BackButton(),
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
                  padding: const EdgeInsets.only(bottom: 64),
                  itemCount: filteredConnections.length,
                  itemBuilder: (context, index) {
                    final connection = filteredConnections[index];
                    return ConnectionTile(
                      onPressed: () => setState(
                          () => _openIndex = _openIndex == index ? -1 : index),
                      profile: connection,
                      expanded: _openIndex == index,
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
}

class ConnectionTile extends StatefulWidget {
  final VoidCallback? onPressed;
  final PublicProfile profile;
  final bool expanded;

  const ConnectionTile({
    Key? key,
    required this.onPressed,
    required this.profile,
    required this.expanded,
  }) : super(key: key);

  @override
  State<ConnectionTile> createState() => _ConnectionTileState();
}

class _ConnectionTileState extends State<ConnectionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Button(
            onPressed: widget.onPressed,
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
                  child: ProfilePhoto(url: widget.profile.photo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: Theming.of(context).text.subheading,
                      ),
                      Text(
                        widget.profile.description,
                        style: Theming.of(context)
                            .text
                            .body
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
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
              margin:
                  const EdgeInsets.only(left: 92, right: 16, bottom: 8, top: 4),
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
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        'public-profile',
                        arguments: PublicProfileArguments(
                          publicProfile: widget.profile,
                          editable: false,
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.account_circle,
                    ),
                  ),
                  Button(
                    onPressed: () {},
                    child: const Icon(
                      Icons.phone,
                    ),
                  ),
                  Button(
                    onPressed: () {},
                    child: const Icon(
                      Icons.message,
                    ),
                  ),
                  Button(
                    onPressed: () {},
                    child: const Icon(
                      Icons.videocam_sharp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
