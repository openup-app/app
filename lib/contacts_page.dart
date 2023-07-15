import 'package:flutter/material.dart';
import 'package:openup/widgets/invite_friends.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _filterString = '';

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
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 16),
            child: FriendsSearchField(
              controller: _searchController,
              focusNode: _searchFocusNode,
            ),
          ),
          Expanded(
            child: InviteFriends(
              padding: EdgeInsets.only(
                top: 0,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              filter: _filterString,
            ),
          ),
        ],
      ),
    );
  }
}
