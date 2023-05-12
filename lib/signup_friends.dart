import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/invite_friends.dart';

class SignUpFriends extends StatefulWidget {
  const SignUpFriends({super.key});

  @override
  State<SignUpFriends> createState() => _SignUpFriendsState();
}

class _SignUpFriendsState extends State<SignUpFriends> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _filterString = '';

  @override
  void initState() {
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
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
                        'initialLoading',
                        queryParams: {'welcome': 'true'},
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
