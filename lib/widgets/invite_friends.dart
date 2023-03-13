import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteFriends extends StatefulWidget {
  final EdgeInsets padding;
  final String filter;

  const InviteFriends({
    super.key,
    this.padding = EdgeInsets.zero,
    this.filter = '',
  });

  @override
  State<InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends State<InviteFriends> {
  bool _hasContactsPermission = false;
  bool _error = false;

  List<KnownContactProfile>? _knownProfiles;
  List<Contact>? _contacts;

  @override
  void initState() {
    super.initState();
    Permission.contacts.status.then((status) {
      if (mounted) {
        _hasContactsPermission = status == PermissionStatus.granted;
        _fetchContacts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContactsPermission) {
      return Center(
        child: PermissionButton(
          icon: const Icon(Icons.import_contacts),
          label: const Text('Enable Contacts'),
          granted: _hasContactsPermission,
          onPressed: () async {
            final status = await Permission.contacts.request();
            if (mounted && status == PermissionStatus.granted) {
              _fetchContacts();
            }
          },
        ),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to get contacts',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 12,
                  color: Colors.white),
            ),
            ElevatedButton(
              child: const Text('Retry'),
              onPressed: () => _fetchContacts(),
            ),
          ],
        ),
      );
    }

    final knownProfiles = _knownProfiles
        ?.where((c) =>
            c.profile.name.toLowerCase().contains(widget.filter.toLowerCase()))
        .toList();
    final contacts = _contacts
        ?.where((c) =>
            c.displayName.toLowerCase().contains(widget.filter.toLowerCase()))
        .toList();
    if (knownProfiles == null || contacts == null) {
      return const Center(
        child: LoadingIndicator(),
      );
    }
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: _Heading(label: 'Contacts using Openup'),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: knownProfiles.length,
            (context, index) {
              final knownProfile = knownProfiles[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      knownProfile.profile.name,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 20,
                          color: Colors.white),
                    ),
                    subtitle: Text(
                      'Friends ${knownProfile.profile.friendCount}',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w300,
                          fontSize: 12,
                          color: Colors.white),
                    ),
                    trailing: _InviteButton(
                      phoneNumber: knownProfile.phoneNumber,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: _Heading(label: 'Invite your contacts'),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: contacts.length,
            (context, index) {
              final contact = contacts[index];
              final phoneNumber =
                  contact.phones.isEmpty ? '' : contact.phones.first.number;
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  clipBehavior: Clip.hardEdge,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: contact.photoOrThumbnail != null
                      ? Image.memory(contact.photoOrThumbnail!)
                      : const SizedBox.shrink(),
                ),
                title: Text(
                  contact.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: 20,
                      color: Colors.white),
                ),
                trailing: _InviteButton(
                  phoneNumber:
                      contact.phones.isEmpty ? '' : contact.phones.first.number,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _fetchContacts() async {
    setState(() => _error = false);

    final status = await Permission.contacts.status;
    if (status != PermissionStatus.granted) {
      return;
    }
    if (mounted) {
      setState(() => _hasContactsPermission = true);
    }
    final allContacts = await FlutterContacts.getContacts(
      withThumbnail: true,
      withProperties: true,
    );

    if (!mounted) {
      return;
    }

    final contacts = allContacts.where((c) => c.phones.isNotEmpty).toList();
    final api = GetIt.instance.get<Api>();
    final result = await api.getKnownContactProfiles(
        contacts.map((e) => e.phones.first.number).toList());
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {
        displayError(context, l);
        setState(() => _error = true);
      },
      (r) {
        final knownProfiles = r;
        for (final knownProfile in knownProfiles) {
          contacts.removeWhere(
              (c) => c.phones.first.number == knownProfile.phoneNumber);
        }

        setState(() {
          _knownProfiles = knownProfiles;
          _contacts = contacts;
        });
      },
    );
  }
}

class _InviteButton extends StatelessWidget {
  final String phoneNumber;
  const _InviteButton({
    super.key,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => _launchMessagingApp(phoneNumber),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: DecoratedBox(
          decoration: const BoxDecoration(
              color: Color.fromRGBO(0xD9, 0xD9, 0xD9, 0.25),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Text(
              'invite',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _launchMessagingApp(String phoneNumber) {
    final querySymbol = Platform.isAndroid ? '?' : '&';
    final body = Uri.encodeComponent(
        'I\'m on Openup, a new way to meet online. \nhttps://openupfriends.com');
    print(body);
    final url = Uri.parse('sms://$phoneNumber/${querySymbol}body=$body');
    launchUrl(url);
  }
}

class _Heading extends StatelessWidget {
  final String label;
  const _Heading({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: const Color.fromRGBO(0xA1, 0xA1, 0xA1, 1.0)),
            ),
          ),
          const RotatedBox(
            quarterTurns: 1,
            child: Icon(
              Icons.chevron_right,
              color: Color.fromRGBO(0x88, 0x88, 0x88, 1.0),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadCollectionList extends StatefulWidget {
  final String uid;
  const _LoadCollectionList({
    super.key,
    required this.uid,
  });

  @override
  State<_LoadCollectionList> createState() => _LoadCollectionListState();
}

class _LoadCollectionListState extends State<_LoadCollectionList> {
  List<Collection>? _collections;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  void _fetchCollections() async {
    final api = GetIt.instance.get<Api>();
    final result = await api.getCollections(widget.uid);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) => setState(() => _error = true),
      (r) => setState(() => _collections = r),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Text(
        'Failed to load collection',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w300, fontSize: 12, color: Colors.white),
      );
    }
    return const Center(
      child: LoadingIndicator(
        size: 32,
      ),
    );
  }
}
