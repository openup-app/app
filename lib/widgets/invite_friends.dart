import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/contacts/contacts_provider.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';
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
    ref
        .read(contactsProvider.notifier)
        .refreshContacts(canRequestPermission: false);
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
                      ref
                          .read(contactsProvider.notifier)
                          .refreshContacts(canRequestPermission: true);
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
          child: SectionTitle(title: Text('Contacts using Plus One')),
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
                    child: LoadingIndicator(),
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
                              color: Colors.white,
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
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
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
                    margin: const EdgeInsets.only(left: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
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
                              color: Colors.black,
                            ),
                          ),
                  ),
                  title: Text(
                    contact.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  trailing: _InviteButton(
                    onPressed: () {
                      final dynamicConfig = ref.read(dynamicConfigProvider);
                      final message = dynamicConfig.contactInviteMessage;
                      final body = Uri.encodeComponent(message);
                      _launchMessagingApp(contact.phoneNumber, body);
                    },
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
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Add',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color.fromRGBO(0x34, 0x78, 0xF6, 1.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _launchMessagingApp(String phoneNumber, String body) {
  final querySymbol = Platform.isAndroid ? '?' : '&';
  final url = Uri.parse('sms://$phoneNumber/${querySymbol}body=$body');
  launchUrl(url);
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
      margin: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search,
                      size: 16,
                      color: Colors.black,
                    ),
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
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
