import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';

class RawUsersApi {
  final _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  final String _urlBase;

  RawUsersApi({
    required String host,
    required int port,
    String? authToken,
  }) : _urlBase = 'http://$host:$port' {
    if (authToken != null) {
      this.authToken = authToken;
    }
  }

  set authToken(String value) {
    _headers['Authorization'] = 'Bearer $value';
  }

  Future<void> createUser({
    required String uid,
    required DateTime birthday,
  }) async {
    final response = await http.post(
      Uri.parse('$_urlBase/users/$uid'),
      headers: _headers,
      body: jsonEncode({
        'birthday': birthday.toIso8601String(),
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

  Future<void> deleteUser(String uid) async {
    final response = await http.delete(
      Uri.parse('$_urlBase/users/$uid'),
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

  Future<bool> checkBirthday({
    required String phone,
    required DateTime birthday,
  }) async {
    final response = await http.post(
      Uri.parse('$_urlBase/users/any/check_birthday'),
      headers: _headers,
      body: jsonEncode({
        'phone': phone,
        'birthday': birthday.toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Invalid creation');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
    final resultMap = jsonDecode(response.body);
    return resultMap['success'];
  }

  Future<bool> getOnboarded(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/onboarded'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get onboarded');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    return jsonDecode(response.body)['onboarded'] == true;
  }

  Future<void> updateOnboarded(String uid, bool onboarded) async {
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/onboarded'),
      headers: _headers,
      body: jsonEncode({onboarded: onboarded}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update onboarded');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<PublicProfile> getProfile(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/profile'),
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

  Future<void> updateProfile(String uid, PublicProfile profile) async {
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/profile'),
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

  Future<String> updateProfileGalleryPhoto(
    String uid,
    Uint8List photo,
    int index,
  ) async {
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/profile/gallery/$index'),
      headers: {
        ..._headers,
        'Content-Type': 'application/octet-stream',
      },
      body: photo,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update profile gallery photo');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  Future<void> deleteProfileGalleryPhoto(String uid, int index) async {
    final response = await http.delete(
      Uri.parse('$_urlBase/users/$uid/profile/gallery/$index'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to delete profile gallery photo');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<String> updateProfileAudio(String uid, Uint8List audio) async {
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/profile/audio'),
      headers: {
        ..._headers,
        'Content-Type': 'application/octet-stream',
      },
      body: audio,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update profile audio');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['url'] as String;
  }

  Future<void> deleteProfileAudio(String uid) async {
    final response = await http.delete(
      Uri.parse('$_urlBase/users/$uid/profile/audio'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to delete profile audio');
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
      Uri.parse('$_urlBase/users/$uid/preferences/$type'),
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

  Future<PrivateProfile> getAttributes(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/attributes'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get attributes');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    return PrivateProfile.fromJson(jsonDecode(response.body));
  }

  Future<void> updateAttributes(String uid, PrivateProfile attributes) async {
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/attributes'),
      headers: _headers,
      body: jsonEncode(attributes.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update attributes');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
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
    final response = await http.put(
      Uri.parse('$_urlBase/users/$uid/preferences/$type'),
      headers: _headers,
      body: jsonEncode(preferences.toJson()),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update $type preferences');
      }
      return Future.error('Failure');
    }
  }

  Future<List<Rekindle>> getRekindles(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/rekindles'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get rekindles');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<Rekindle>.from(list.map((e) => Rekindle.fromJson(e)));
  }

  Future<void> addConnectionRequest(String uid, String otherUid) async {
    final response = await http.post(
      Uri.parse('$_urlBase/users/$otherUid/connection_requests'),
      headers: _headers,
      body: jsonEncode({'uid': uid}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to request connection');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<List<Connection>> getConnections(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/connections'),
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
    return List<Connection>.from(list.map((e) => Connection.fromJson(e)));
  }

  Future<List<Connection>> deleteConnection(
    String uid,
    String deleteUid,
  ) async {
    final response = await http.delete(
      Uri.parse('$_urlBase/users/$uid/connections/$deleteUid'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to delete connection');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return List<Connection>.from(list.map((e) => Connection.fromJson(e)));
  }

  Future<Map<String, int>> getUnreadMessageCount(String uid) async {
    final response = await http.get(
      Uri.parse('$_urlBase/users/$uid/unread_message_count'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to get unread message count');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }

    return Map<String, int>.from(jsonDecode(response.body));
  }

  Future<void> addNotificationTokens(
    String uid, {
    String? messagingToken,
    String? voipToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_urlBase/users/$uid/notification_tokens'),
      headers: _headers,
      body: jsonEncode({
        if (messagingToken != null) ...{'messaging_token': messagingToken},
        if (voipToken != null) ...{'voip_token': voipToken},
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to update notification token');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<void> reportUser({
    required String uid,
    required String reportedUid,
    required String reason,
    String? extra,
  }) async {
    final response = await http.post(
      Uri.parse('$_urlBase/users/$reportedUid/reports'),
      headers: _headers,
      body: jsonEncode({
        'reporterUid': uid,
        'reason': reason,
        'extra': extra,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to report user');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }

  Future<String> call(
    String calleeUid,
    bool video, {
    required bool group,
  }) async {
    final response = await http.post(
      Uri.parse('$_urlBase/calls/'),
      headers: _headers,
      body: jsonEncode({
        'calleeUid': calleeUid,
        'video': video,
        'group': group,
      }),
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

  Future<void> contactUs({required String uid, required String message}) async {
    final response = await http.post(
      Uri.parse('$_urlBase/support/contact_us'),
      headers: _headers,
      body: jsonEncode({
        'uid': uid,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 400) {
        return Future.error('Failed to send message');
      }
      print('Error ${response.statusCode}: ${response.body}');
      return Future.error('Failure');
    }
  }
}
