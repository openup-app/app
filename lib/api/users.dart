import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:openup/preferences.dart';

late final Provider<UsersApi> usersApiProvider;

void initUsersApi({required String host}) {
  usersApiProvider = Provider<UsersApi>((ref) {
    return UsersApi(host: host);
  });
}

class UsersApi {
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final String host;

  UsersApi({required this.host});

  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required DateTime birthday,
  }) async {
    final response = await http.post(
      Uri.parse('http://$host/users/'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
        'birthday': birthday.toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Invalid sign-up';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<void> createUserWithUid({
    required String uid,
    required DateTime birthday,
  }) async {
    final response = await http.post(
      Uri.parse('http://$host/users/$uid/create'),
      headers: _headers,
      body: jsonEncode({
        'birthday': birthday.toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Invalid creation';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<void> deleteUser(String uid) async {
    final response = await http.delete(
      Uri.parse('http://$host/users/$uid'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to delete user';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<Preferences> getPreferences(String uid) async {
    final response = await http.get(
      Uri.parse('http://$host/users/$uid/preferences'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get preferences';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    return Preferences.fromJson(jsonDecode(response.body));
  }

  Future<void> updatePreferences(String uid, Preferences preferences) async {
    final response = await http.patch(
      Uri.parse('http://$host/users/$uid/preferences'),
      headers: _headers,
      body: jsonEncode(preferences.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to update preferences';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }
}
