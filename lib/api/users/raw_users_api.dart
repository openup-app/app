import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openup/api/users/account.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';

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

  Future<PublicProfile> getPublicProfile(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/profile/public'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get profile';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    return PublicProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> updatePublicProfile(String uid, PublicProfile profile) async {
    final response = await http.patch(
      Uri.parse('http://$_host/users/$uid/profile/public'),
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

  Future<PrivateProfile> getPrivateProfile(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/profile/private'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get profile';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    return PrivateProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> updatePrivateProfile(String uid, PrivateProfile profile) async {
    final response = await http.patch(
      Uri.parse('http://$_host/users/$uid/profile/private'),
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

  Future<String> updateGalleryPhoto(
    String uid,
    Uint8List photo,
    int index,
  ) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/public/gallery/$index'),
      headers: {
        ..._headers,
        'Content-Type': 'application/octet-stream',
      },
      body: photo,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to upload photo';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  Future<void> deleteGalleryPhoto(String uid, int index) async {
    final response = await http.delete(
      Uri.parse('http://$_host/users/$uid/public/gallery/$index'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to delete photo';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }
  }

  Future<String> updateAudioBio(String uid, Uint8List audio) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/public/audio'),
      headers: {
        ..._headers,
        'Content-Type': 'application/octet-stream',
      },
      body: audio,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to upload audio';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  Future<void> deleteAudioBio(String uid) async {
    final response = await http.delete(
      Uri.parse('http://$_host/users/$uid/public/audio'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to delete audio';
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

  Future<int> getPossibleFriendCount(String uid, Preferences preferences) =>
      _getPossibleCount(uid, preferences, 'friends');

  Future<int> getPossibleDateCount(String uid, Preferences preferences) =>
      _getPossibleCount(uid, preferences, 'dating');

  Future<int> _getPossibleCount(
    String uid,
    Preferences preferences,
    String type,
  ) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/possible/$type'),
      headers: _headers,
      body: jsonEncode(preferences.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get possible matches';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['matches'] as int;
  }

  Future<List<Rekindle>> getRekindleList(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/rekindles'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        throw 'Failed to get rekindle list';
      }
      print('Error ${response.statusCode}: ${response.body}');
      throw 'Failure';
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<Rekindle>.from(list.map((e) => Rekindle.fromJson(e)));
  }
}
