import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/contacts/contacts_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/invite_friends.dart';
import 'package:openup/widgets/scaffold.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});

  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _filterString = '';

  @override
  void initState() {
    super.initState();
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
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: OpenupAppBar(
        body: OpenupAppBarBody(
          leading: Button(
            onPressed: Navigator.of(context).pop,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Cancel'),
            ),
          ),
          center: const Text('Contacts'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
                bottom: 16,
              ),
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
      ),
    );
  }
}
