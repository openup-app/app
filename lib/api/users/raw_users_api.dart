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
        return Future.error('Invalid sign-up');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<void> createUserWithUid({
    required String uid,
    required DateTime birthday,
    required String? notificationToken,
  }) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/create'),
      headers: _headers,
      body: jsonEncode({
        'birthday': birthday.toIso8601String(),
        'notificationToken': notificationToken,
      }),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Invalid creation');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<Account> getAccount(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/account'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get account');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to update preferences');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<PublicProfile> getPublicProfile(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/profile/public'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get profile');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to update profile');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<PrivateProfile> getPrivateProfile(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/profile/private'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get profile');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to update profile');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to upload photo');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to delete photo');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to upload audio');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to delete audio');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<void> deleteUser(String uid) async {
    final response = await http.delete(
      Uri.parse('http://$_host/users/$uid'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to delete user');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to get preferences');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to update preferences');
      }
      return Future.error('Failure');
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
        return Future.error('Failed to get possible matches');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
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
        return Future.error('Failed to get rekindle list');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<Rekindle>.from(list.map((e) => Rekindle.fromJson(e)));
  }

  Future<void> addConnectionRequest(String uid, String otherUid) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/connection_request'),
      headers: _headers,
      body: jsonEncode({'uid': otherUid}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to request connection');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<List<PublicProfile>> getConnections(String uid) async {
    final response = await http.get(
      Uri.parse('http://$_host/users/$uid/connections'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get connections');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<PublicProfile>.from(list.map((e) => PublicProfile.fromJson(e)));
  }

  Future<List<PublicProfile>> deleteConnection(
    String uid,
    String deleteUid,
  ) async {
    final response = await http.delete(
      Uri.parse('http://$_host/users/$uid/connections'),
      headers: _headers,
      body: jsonEncode({'uid': deleteUid}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to delete connection');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<PublicProfile>.from(list.map((e) => PublicProfile.fromJson(e)));
  }

  Future<String> call(String uid, String calleeUid, bool video) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$calleeUid/call'),
      headers: _headers,
      body: jsonEncode({'uid': uid, 'video': video}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to call user');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['rid'] as String;
  }

  @override
  Future<void> updateNotificationToken(
    String uid,
    String notificationToken,
  ) async {
    final response = await http.post(
      Uri.parse('http://$_host/users/$uid/notification_token'),
      headers: _headers,
      body: jsonEncode({'notification_token': notificationToken}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update notification token');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }
}
