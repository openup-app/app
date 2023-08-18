import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/contacts/contacts_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';
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
  @override
  void initState() {
    super.initState();
    ref.read(contactsProvider.notifier).refreshContacts();
  }

  @override
  Widget build(BuildContext context) {
    final hasPermission =
        ref.watch(contactsProvider.select((p) => p.hasPermission));
    if (!hasPermission) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: widget.controller,
            child: SizedBox(
              height: constraints.maxHeight,
              child: Center(
                child: PermissionButton(
                  icon: const Icon(
                    Icons.import_contacts,
                    color: Colors.black,
                  ),
                  label: const Text('Enable Contacts'),
                  granted: hasPermission,
                  onPressed: () async {
                    final status = await Permission.contacts.request();
                    if (mounted && status == PermissionStatus.granted) {
                      ref.read(contactsProvider.notifier).refreshContacts();
                    }
                  },
                ),
              ),
            ),
          );
        },
      );
    }

    final filteredState =
        ref.watch(contactsProvider.select((p) => p.filter(widget.filter)));

    final contacts = filteredState.contacts;
    return CustomScrollView(
      controller: widget.controller,
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(height: widget.padding.top),
        ),
        const SliverToBoxAdapter(
          child: SectionTitle(title: Text('Contacts using UT Meets')),
        ),
        Builder(
          builder: (context) {
            return filteredState.knownContactsState.map(
              error: (_) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Failed to load contacts'),
                  ),
                );
              },
              loading: (_) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: LoadingIndicator(
                      color: Colors.black,
                    ),
                  ),
                );
              },
              contacts: (contacts) {
                final knownProfiles = contacts.contacts;
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: knownProfiles.length,
                    (context, index) {
                      final contact = knownProfiles[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: const BoxDecoration(color: Colors.white),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            clipBehavior: Clip.hardEdge,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
                            ),
                            child: contact.photo.isNotEmpty
                                ? Image.network(
                                    contact.photo,
                                    fit: BoxFit.cover,
                                  )
                                : Text(
                                    contact.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          title: Text(
                            contact.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color.fromRGBO(0x34, 0x34, 0x34, 1.0),
                            ),
                          ),
                          trailing: _InviteButton(
                            onPressed: () {
                              showProfileBottomSheetLoadProfile(
                                context: context,
                                uid: contact.uid,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
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
                    child: contact.photo != null
                        ? Image.memory(
                            contact.photo!,
                            fit: BoxFit.cover,
                          )
                        : Text(
                            contact.name.substring(0, 1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  title: Text(
                    contact.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color.fromRGBO(0x34, 0x34, 0x34, 1.0),
                    ),
                  ),
                  trailing: _InviteButton(
                    onPressed: () => _launchMessagingApp(contact.phoneNumber),
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
}

class _InviteButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _InviteButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
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
}

void _launchMessagingApp(String phoneNumber) {
  final querySymbol = Platform.isAndroid ? '?' : '&';
  final body = Uri.encodeComponent(
      'I\'m on UT Meets, a new way to meet online. \nhttps://utmeets.com');
  final url = Uri.parse('sms://$phoneNumber/${querySymbol}body=$body');
  launchUrl(url);
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
        color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
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
