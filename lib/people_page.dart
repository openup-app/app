import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:openup/menu_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  bool _hasContactsPermission = false;
  final _contacts = <Contact>[];

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/people_background.png',
                fit: BoxFit.fill),
          ),
          Positioned.fill(
            child: Builder(
              builder: (context) {
                if (!_hasContactsPermission) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        await _requestPermission();
                        if (mounted) {
                          await _fetchContacts();
                        }
                      },
                      child: Text('Request permission'),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Invite your contacts',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 14,
                                      color: const Color.fromRGBO(
                                          0xA1, 0xA1, 0xA1, 1.0)),
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
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _contacts.length,
                        padding: const EdgeInsets.only(bottom: 72),
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          final phoneNumber = contact.phones.isEmpty
                              ? ''
                              : contact.phones.first.number;
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 20,
                                      color: Colors.white),
                            ),
                            subtitle: Text(
                              phoneNumber,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                      fontWeight: FontWeight.w300,
                                      fontSize: 12,
                                      color: Colors.white),
                            ),
                            trailing: Button(
                              onPressed: () => _launchMessagingApp(phoneNumber),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                      color: Color.fromRGBO(
                                          0xD9, 0xD9, 0xD9, 0.25),
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(4))),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    child: Text(
                                      'invite',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                              fontWeight: FontWeight.w300,
                                              fontSize: 14,
                                              color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (kDebugMode)
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _requestPermission();
                            if (mounted) {
                              await _fetchContacts();
                            }
                          },
                          child: Text('Request permission'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const Positioned(
            right: 32,
            bottom: 32,
            child: MenuButton(
              color: Color.fromRGBO(0xD3, 0x00, 0x00, 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchContacts() async {
    final status = await Permission.contacts.status;
    if (status != PermissionStatus.granted) {
      return;
    }
    final contacts = await FlutterContacts.getContacts(
      withThumbnail: true,
      withProperties: true,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _contacts
        ..clear()
        ..addAll(contacts);
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    if (status == PermissionStatus.granted) {
      if (mounted) {
        setState(() => _hasContactsPermission = true);
      }
    } else if (status == PermissionStatus.permanentlyDenied) {
      if (!mounted) {
        return;
      }
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('Contacts access required'),
            content: Text('Enable contacts access for Openup'),
            actions: [
              CupertinoDialogAction(
                onPressed: Navigator.of(context).pop,
                child: Text('Deny'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: Text('Open settings'),
              ),
            ],
          );
        },
      );
    }
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
