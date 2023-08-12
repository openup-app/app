import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/contacts/contacts_service.dart';

part 'contacts_provider.freezed.dart';

final contactsProvider =
    StateNotifierProvider<ContactsStateNotifier, ContactsState>((ref) {
  return ContactsStateNotifier(ContactsService());
});

class ContactsStateNotifier extends StateNotifier<ContactsState> {
  final ContactsService contactsService;
  ContactsStateNotifier(this.contactsService)
      : super(const ContactsState(contacts: []));

  void refreshContacts() async {
    final hasPermission = await contactsService.hasPermission();
    if (hasPermission || await contactsService.requestPermission()) {
      final contacts = await contactsService.getContacts();
      if (!mounted) {
        return;
      }
      state = ContactsState(
        contacts: contacts.map(
          (e) {
            return Contact(
              name: e.name,
              phoneNumber: e.phoneNumber,
              photo: e.photo,
            );
          },
        ).toList(),
      );
    }
  }
}

@freezed
class ContactsState with _$ContactsState {
  const factory ContactsState({
    required List<Contact> contacts,
  }) = _ContactsState;

  const ContactsState._();

  List<Contact> filter(String filter) {
    return contacts
        .where((c) => c.name.toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }
}

@freezed
class Contact with _$Contact {
  const factory Contact({
    required String name,
    required String phoneNumber,
    @Default(null) Uint8List? photo,
  }) = _Contact;
}
