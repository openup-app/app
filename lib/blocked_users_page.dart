import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({Key? key}) : super(key: key);

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  List<SimpleProfile> _blockedUsers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _getBlockedUsers();
  }

  void _getBlockedUsers() {
    final api = ref.read(apiProvider);
    api.getBlockedUsers().then((value) {
      if (mounted) {
        value.fold(
          (l) => displayError(context, l),
          (r) {
            setState(() {
              _blockedUsers = r..sort((a, b) => a.name.compareTo(b.name));
              _loading = false;
            });
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top + 44),
                SizedBox(
                  height: 44,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Button(
                            onPressed: Navigator.of(context).pop,
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Blocked users',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Here is the list of users you have blocked on Howdy',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(0x9D, 0x9D, 0x9D, 1.0),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(
                        child: LoadingIndicator(
                          color: Colors.white,
                        ),
                      );
                    }
                    if (_blockedUsers.isEmpty) {
                      return Expanded(
                        child: Center(
                          child: Text(
                            'You are not blocking anyone',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontSize: 20),
                          ),
                        ),
                      );
                    }
                    return Expanded(
                      child: ListView.builder(
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          return ListTile(
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Image.network(
                                user.photo,
                                fit: BoxFit.cover,
                              ),
                            ),
                            title: AutoSizeText(
                              user.name,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400),
                            ),
                            trailing: Button(
                              onPressed: () async {
                                final result = await showCupertinoModalPopup(
                                  context: context,
                                  builder: (context) {
                                    return CupertinoActionSheet(
                                      title: Text('Unblock ${user.name}?'),
                                      message: Text(
                                          '${user.name} will be able to send you a friend request again. They won\'t be notified that you unblocked them.'),
                                      cancelButton: CupertinoActionSheetAction(
                                        onPressed: Navigator.of(context).pop,
                                        child: const Text('Cancel'),
                                      ),
                                      actions: [
                                        CupertinoActionSheetAction(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          isDestructiveAction: true,
                                          child: const Text('Unblock'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (result == true) {
                                  final api = ref.read(apiProvider);
                                  final result =
                                      await api.unblockUser(user.uid);
                                  if (mounted) {
                                    result.fold(
                                      (l) => displayError(context, l),
                                      (r) => setState(() => _blockedUsers = r),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(8)),
                                ),
                                child: Text(
                                  'Unblock',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
