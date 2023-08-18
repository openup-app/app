import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/contacts/contacts_service.dart';

part 'contacts_provider.freezed.dart';

final contactsProvider =
    StateNotifierProvider<ContactsStateNotifier, ContactsState>((ref) {
  return ContactsStateNotifier(
    api: ref.read(apiProvider),
    contactsService: ContactsService(),
  );
});

class ContactsStateNotifier extends StateNotifier<ContactsState> {
  final Api api;
  final ContactsService contactsService;

  ContactsStateNotifier({
    required this.api,
    required this.contactsService,
  }) : super(const ContactsState(
          hasPermission: false,
          contacts: [],
          knownContactsState: KnownContactsState.loading(),
        ));

  Future<void> refreshContacts() async {
    var hasPermission = await contactsService.hasPermission();
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      hasPermission: hasPermission,
    );

    if (hasPermission || await contactsService.requestPermission()) {
      hasPermission = true;
      final contacts = await contactsService.getContacts();
      if (!mounted) {
        return;
      }
      state = state.copyWith(
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

    if (mounted) {
      state = state.copyWith(
        hasPermission: hasPermission,
      );
    }
  }

  void uploadContacts() async {
    final contacts = state.contacts;
    if (contacts.isNotEmpty) {
      final result = await api.addContacts(contacts);
      if (!mounted) {
        return;
      }
      result.fold(
        (l) {
          state = state.copyWith(
            knownContactsState: const KnownContactsState.error(),
          );
        },
        (r) {
          state = state.copyWith(
            knownContactsState: KnownContactsState.contacts(r),
          );
        },
      );
    }
  }
}

@freezed
class ContactsState with _$ContactsState {
  const factory ContactsState({
    required bool hasPermission,
    required List<Contact> contacts,
    required KnownContactsState knownContactsState,
  }) = _ContactsState;

  const ContactsState._();

  ContactsState filter(String filter) {
    return copyWith(
      contacts: contacts
          .where((c) => c.name.toLowerCase().contains(filter.toLowerCase()))
          .toList(),
      knownContactsState: knownContactsState.map(
        error: (error) => error,
        loading: (loading) => loading,
        contacts: (contacts) => contacts.copyWith(
          contacts: contacts.contacts
              .where((e) => e.name.toLowerCase().contains(filter.toLowerCase()))
              .toList(),
        ),
      ),
    );
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

@freezed
class KnownContactsState with _$KnownContactsState {
  const factory KnownContactsState.error() = _KnownContactsError;
  const factory KnownContactsState.loading() = _KnownContactsLoading;
  const factory KnownContactsState.contacts(List<KnownContact> contacts) =
      _KnownContactsContacts;
}
