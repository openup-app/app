import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';

/// Displays a list of [Connections] to invite to group calling.
class ConnectionsBottomSheet extends ConsumerStatefulWidget {
  final ScrollController? controller;
  final void Function(Profile profile) onSelected;
  const ConnectionsBottomSheet({
    Key? key,
    this.controller,
    required this.onSelected,
  }) : super(key: key);

  @override
  _ConnectionsBottomSheetState createState() => _ConnectionsBottomSheetState();
}

class _ConnectionsBottomSheetState extends ConsumerState<ConnectionsBottomSheet>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  List<Connection>? _connections;

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
    final uid = ref.read(userProvider).uid;
    api.getConnections(uid).then((result) {
      if (!mounted) {
        return;
      }

      result.fold(
        (l) => displayError(context, l),
        (r) {
          _animationController = BottomSheet.createAnimationController(this);
          setState(() => _connections = r);
        },
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _animationController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      backgroundColor: Colors.transparent,
      animationController: _animationController,
      onClosing: () {},
      builder: (context) {
        return Container(
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(48),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(0xFF, 0x59, 0x59, 0.75),
                Color.fromRGBO(0x3E, 0x00, 0x00, 0.6525),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Invite a friend',
                  style: Theming.of(context)
                      .text
                      .subheading
                      .copyWith(fontWeight: FontWeight.w300),
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final connections = _connections;
                    if (connections == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView.builder(
                      controller: widget.controller,
                      itemCount: connections.length,
                      itemBuilder: (context, index) {
                        final connection = connections[index];
                        final profile = connection.profile;
                        return Button(
                          onPressed: () => widget.onSelected(profile),
                          child: SizedBox(
                            height: 96,
                            child: Row(
                              children: [
                                const SizedBox(width: 32),
                                Container(
                                  width: 42,
                                  height: 56,
                                  clipBehavior: Clip.hardEdge,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    color: Colors.blue,
                                  ),
                                  child: ProfilePhoto(
                                    url: profile.photo,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  profile.name,
                                  style: Theming.of(context).text.subheading,
                                ),
                                const Spacer(),
                                Image.asset('assets/images/chevron_right.png'),
                                const SizedBox(width: 48),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
