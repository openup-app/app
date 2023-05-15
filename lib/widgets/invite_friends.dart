import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/section.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class InviteFriends extends ConsumerStatefulWidget {
  final EdgeInsets padding;
  final ScrollController? controller;
  final String filter;

  const InviteFriends({
    super.key,
    this.padding = EdgeInsets.zero,
    this.controller,
    this.filter = '',
  });

  @override
  ConsumerState<InviteFriends> createState() => _InviteFriendsState();
}

class _InviteFriendsState extends ConsumerState<InviteFriends> {
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
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: widget.controller,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
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
              ),
            ),
          );
        },
      );
    }

    if (_error) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: widget.controller,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
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
              ),
            ),
          );
        },
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
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: widget.controller,
            child: SizedBox(
              height: constraints.maxHeight,
              child: const Center(
                child: LoadingIndicator(),
              ),
            ),
          );
        },
      );
    }
    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: widget.padding.top),
        ),
        const SliverToBoxAdapter(
          child: SectionTitle(title: Text('Contacts using bff')),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: knownProfiles.length,
            (context, index) {
              final knownProfile = knownProfiles[index];
              return DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        knownProfile.profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                      ),
                      subtitle: Text(
                        '${knownProfile.profile.friendCount} friends on bff',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w300,
                              fontSize: 12,
                            ),
                      ),
                      trailing: _InviteButton(
                        phoneNumber: knownProfile.phoneNumber,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionTitle(title: Text('Invite contacts')),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            childCount: contacts.length,
            (context, index) {
              final contact = contacts[index];
              final isFirst = index == 0;
              final isLast = index == contacts.length - 1;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
                    topRight: isFirst ? const Radius.circular(16) : Radius.zero,
                    bottomLeft:
                        isLast ? const Radius.circular(16) : Radius.zero,
                    bottomRight:
                        isLast ? const Radius.circular(16) : Radius.zero,
                  ),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    clipBehavior: Clip.hardEdge,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                    ),
                    child: contact.photoOrThumbnail != null
                        ? Image.memory(contact.photoOrThumbnail!)
                        : Text(
                            contact.displayName.substring(0, 1).toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontWeight: FontWeight.w400, fontSize: 16),
                          ),
                  ),
                  title: Text(
                    contact.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: const Color.fromRGBO(0x34, 0x34, 0x34, 1.0)),
                  ),
                  subtitle: Text(
                    '0 friends on bff',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w300,
                        fontSize: 12,
                        color: const Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0)),
                  ),
                  trailing: _InviteButton(
                    phoneNumber: contact.phones.isEmpty
                        ? ''
                        : contact.phones.first.number,
                  ),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: widget.padding.bottom,
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
    final api = ref.read(apiProvider);
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
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0xF5, 0xF5, 0xF5, 1.0),
            borderRadius: const BorderRadius.all(Radius.circular(58)),
            border: Border.all(
              color: const Color.fromRGBO(0x34, 0x78, 0xF6, 1.0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Add',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: const Color.fromRGBO(0x34, 0x78, 0xF6, 1.0)),
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

class _LoadCollectionList extends ConsumerStatefulWidget {
  final String uid;
  const _LoadCollectionList({
    super.key,
    required this.uid,
  });

  @override
  ConsumerState<_LoadCollectionList> createState() =>
      _LoadCollectionListState();
}

class _LoadCollectionListState extends ConsumerState<_LoadCollectionList> {
  List<Collection>? _collections;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  void _fetchCollections() async {
    final api = ref.read(apiProvider);
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

class FriendsSearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const FriendsSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 14, fontWeight: FontWeight.w300),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Search',
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                ),
              ),
            ),
            if (controller.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Button(
                  onPressed: () {
                    controller.text = '';
                    FocusScope.of(context).unfocus();
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.black,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
