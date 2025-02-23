import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/contacts/contacts_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/invite_friends.dart';

class SignUpFriends extends ConsumerStatefulWidget {
  const SignUpFriends({super.key});

  @override
  ConsumerState<SignUpFriends> createState() => _SignUpFriendsState();
}

class _SignUpFriendsState extends ConsumerState<SignUpFriends> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _filterString = '';

  @override
  void initState() {
    ref
        .read(contactsProvider.notifier)
        .refreshContacts(canRequestPermission: false)
        .then((_) {
      if (mounted) {
        ref.read(contactsProvider.notifier).uploadContacts();
      }
    });
    _searchController.addListener(() {
      if (_filterString != _searchController.text) {
        setState(() => _filterString = _searchController.text);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Text(
                  'Add your contacts',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Button(
                    onPressed: () {
                      context.goNamed(
                        'discover',
                        queryParameters: {'welcome': 'true'},
                      );
                    },
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 7, horizontal: 16),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: FriendsSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
            ),
          ),
          Expanded(
            child: InviteFriends(
              padding: EdgeInsets.only(
                top: 0,
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              filter: _filterString,
            ),
          ),
        ],
      ),
    );
  }
}
