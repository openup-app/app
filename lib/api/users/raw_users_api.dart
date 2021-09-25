import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openup/api/users/account.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';

class RawUsersApi {
  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final String _host;

  RawUsersApi({required String host}) : _host = host;

  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required DateTime birthday,
  }) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/'),
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
      Uri.parse('http://$_host/users/$uid/create'),
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

  Future<Account> getAccount(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/account'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get account';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    return Account.fromJson(jsonDecode(response.body));
  }

  Future<void> updateAccount(String uid, Account account) async {
    final response = await http.patch(
      Uri.parse('http://$_host/users/$uid/account'),
      headers: _headers,
      body: jsonEncode(account.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to update preferences';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<Profile> getProfile(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/profile'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get profile';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    return Profile.fromJson(jsonDecode(response.body));
  }

  Future<void> updateProfile(String uid, Profile profile) async {
    final response = await http.patch(
      Uri.parse('http://$_host/users/$uid/profile'),
      headers: _headers,
      body: jsonEncode(profile.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to update profile';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<void> deleteUser(String uid) async {
    final response = await http.delete(
      Uri.parse('http://$_host/users/$uid'),
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

  Future<Preferences> getFriendsPreferences(String uid) =>
      _getPreferences(uid, 'friends');

  Future<Preferences> getDatingPreferences(String uid) =>
      _getPreferences(uid, 'dating');

  Future<Preferences> _getPreferences(String uid, String type) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/preferences/$type'),
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

  Future<void> updateFriendsPreferences(String uid, Preferences preferences) =>
      _updatePreferences(uid, preferences, 'friends');

  Future<void> updateDatingPreferences(String uid, Preferences preferences) =>
      _updatePreferences(uid, preferences, 'dating');

  Future<void> _updatePreferences(
    String uid,
    Preferences preferences,
    String type,
  ) async {
    final response = await http.patch(
      Uri.parse('http://$_host/users/$uid/preferences/$type'),
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
