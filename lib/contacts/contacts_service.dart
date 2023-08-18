import 'package:flutter_contacts/flutter_contacts.dart' hide Contact;
import 'package:openup/contacts/contacts_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsService {
  final _permission = Permission.contacts;

  Future<bool> hasPermission() async {
    final status = await _permission.status;
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<bool> requestPermission() async {
    final status = await _permission.request();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  Future<List<Contact>> getContacts() async {
    if (!await hasPermission()) {
      return Future.value([]);
    }

    final allContacts = await FlutterContacts.getContacts(
      withThumbnail: true,
      withProperties: true,
    );

    return allContacts.map((e) {
      return Contact(
        name: e.displayName,
        phoneNumber: e.phones.isEmpty ? '' : e.phones.first.number,
        photo: e.photoOrThumbnail,
      );
    }).toList();
  }
}
