import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/raw_users_api.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:rxdart/subjects.dart';

late Provider<UsersApi> usersApiProvider;
late StateProvider<PublicProfile?> profileProvider;

late StateController<PublicProfile?> _profileStateController;

void initUsersApi({
  required String host,
  required int port,
  String? authToken,
}) {
  profileProvider = StateProvider<PublicProfile?>((ref) {
    return null;
  });
  usersApiProvider = Provider<UsersApi>((ref) {
    _profileStateController = ref.read(profileProvider.state);
    return UsersApi(
      host: host,
      port: port,
      authToken: authToken,
    );
  });
}

class UsersApi implements RawUsersApi {
  final RawUsersApi _rawUsersApi;
  String? _uid;
  bool? _onboarded;
  PublicProfile? _publicProfile;
  PrivateProfile? _privateProfile;
  Preferences? _friendsPreferences;
  Preferences? _datingPreferences;
  Map<String, int> _unreadChatMessageCounts = {};
  final _unreadChatMessageCountsController =
      BehaviorSubject<Map<String, int>>();

  UsersApi({
    required String host,
    required int port,
    String? authToken,
  }) : _rawUsersApi = RawUsersApi(
          host: host,
          port: port,
          authToken: authToken,
        );

  Future<void> dispose() {
    return _unreadChatMessageCountsController.close();
  }

  set uid(String value) => _uid = value;

  @override
  set authToken(String value) => _rawUsersApi.authToken = value;

  @override
  Future<void> createUser({
    required String uid,
    required DateTime birthday,
  }) async {
    await _rawUsersApi.createUser(
      uid: uid,
      birthday: birthday,
    );
    _clearCache();
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _rawUsersApi.deleteUser(uid);
    _clearCache();
  }

  @override
  Future<bool> checkBirthday({
    required String phone,
    required DateTime birthday,
  }) =>
      _rawUsersApi.checkBirthday(phone: phone, birthday: birthday);

  @override
  Future<void> updateOnboarded(String uid, bool onboarded) {
    if (uid == _uid) {
      _onboarded = onboarded;
    }
    return _rawUsersApi.updateOnboarded(uid, onboarded);
  }

  @override
  Future<bool> getOnboarded(String uid) async {
    if (uid == _uid && _onboarded != null) {
      return _onboarded!;
    }

    final onboarded = await _rawUsersApi.getOnboarded(uid);
    if (uid == _uid) {
      _onboarded = onboarded;
    }
    return onboarded;
  }

  @override
  Future<PublicProfile> getProfile(String uid) async {
    if (uid == _uid && _publicProfile != null) {
      return _publicProfile!;
    }

    final publicProfile = await _rawUsersApi.getProfile(uid);
    if (uid == _uid) {
      _publicProfile = publicProfile;
      _profileStateController.state = _publicProfile;
    }
    return publicProfile;
  }

  @override
  Future<void> updateProfile(String uid, PublicProfile profile) {
    if (uid == _uid) {
      _publicProfile = profile;
      _profileStateController.state = _publicProfile;
    }
    return _rawUsersApi.updateProfile(uid, profile);
  }

  @override
  Future<String> updateProfileGalleryPhoto(
    String uid,
    Uint8List photo,
    int index,
  ) async {
    final url = await _rawUsersApi.updateProfileGalleryPhoto(uid, photo, index);
    final gallery = List<String>.of(_publicProfile?.gallery ?? []);
    if (index < gallery.length) {
      gallery[index] = url;
    } else {
      gallery.add(url);
    }

    _publicProfile = _publicProfile?.copyWith(gallery: gallery);
    _profileStateController.state = _publicProfile;
    return url;
  }

  @override
  Future<void> deleteProfileGalleryPhoto(String uid, int index) async {
    await _rawUsersApi.deleteProfileGalleryPhoto(uid, index);
    final gallery = List<String>.of(_publicProfile?.gallery ?? []);
    gallery.removeAt(index);
    _publicProfile = _publicProfile?.copyWith(gallery: gallery);
    _profileStateController.state = _publicProfile;
  }

  @override
  Future<String> updateProfileAudio(String uid, Uint8List audio) async {
    final url = await _rawUsersApi.updateProfileAudio(uid, audio);
    _publicProfile = _publicProfile?.copyWith(audio: url);
    _profileStateController.state = _publicProfile;
    return url;
  }

  @override
  Future<void> deleteProfileAudio(String uid) async {
    await _rawUsersApi.deleteProfileAudio(uid);
    _publicProfile = _publicProfile?.copyWith(audio: null);
    _profileStateController.state = _publicProfile;
  }

  @override
  Future<PrivateProfile> getAttributes(String uid) async {
    if (uid == _uid && _privateProfile != null) {
      return _privateProfile!;
    }

    final privateProfile = await _rawUsersApi.getAttributes(uid);
    if (uid == _uid) {
      _privateProfile = privateProfile;
    }
    return privateProfile;
  }

  @override
  Future<void> updateAttributes(String uid, PrivateProfile profile) {
    _privateProfile = profile;
    return _rawUsersApi.updateAttributes(uid, profile);
  }

  @override
  Future<Preferences> getFriendsPreferences(String uid) async {
    _friendsPreferences ??= await _rawUsersApi.getFriendsPreferences(uid);
    return _friendsPreferences!;
  }

  @override
  Future<Preferences> getDatingPreferences(String uid) async {
    _datingPreferences ??= await _rawUsersApi.getDatingPreferences(uid);
    return _datingPreferences!;
  }

  @override
  Future<void> updateFriendsPreferences(String uid, Preferences preferences) {
    _friendsPreferences = preferences;
    return _rawUsersApi.updateFriendsPreferences(uid, preferences);
  }

  @override
  Future<void> updateDatingPreferences(String uid, Preferences preferences) {
    _datingPreferences = preferences;
    return _rawUsersApi.updateDatingPreferences(uid, preferences);
  }

  @override
  Future<List<Rekindle>> getRekindles(String uid) =>
      _rawUsersApi.getRekindles(uid);

  @override
  Future<void> addConnectionRequest(String uid, String otherUid) =>
      _rawUsersApi.addConnectionRequest(uid, otherUid);

  @override
  Future<List<Connection>> getConnections(String uid) =>
      _rawUsersApi.getConnections(uid);

  @override
  Future<List<Connection>> deleteConnection(String uid, String deleteUid) =>
      _rawUsersApi.deleteConnection(uid, deleteUid);

  @override
  Future<String> call(
    String calleeUid,
    bool video, {
    bool group = false,
  }) =>
      _rawUsersApi.call(calleeUid, video, group: group);

  @override
  Future<Map<String, int>> getUnreadMessageCount(String uid) async {
    final counts = await _rawUsersApi.getUnreadMessageCount(uid);
    _unreadChatMessageCounts = counts;
    _unreadChatMessageCountsController.add(_unreadChatMessageCounts);
    return counts;
  }

  @override
  Future<void> addNotificationTokens(
    String uid, {
    String? messagingToken,
    String? voipToken,
  }) =>
      _rawUsersApi.addNotificationTokens(
        uid,
        messagingToken: messagingToken,
        voipToken: voipToken,
      );

  bool? get onboarded => _onboarded;

  PublicProfile? get publicProfile => _publicProfile;

  Map<String, int> get unreadChatMessageCounts => _unreadChatMessageCounts;

  Stream<Map<String, int>> get unreadChatMessageCountsStream =>
      _unreadChatMessageCountsController.stream;

  void updateUnreadChatMessagesCount(String uid, int count) {
    _unreadChatMessageCounts[uid] = count;
    _unreadChatMessageCountsController.add(_unreadChatMessageCounts);
  }

  Stream<int> get unreadChatMessageSumStream =>
      _unreadChatMessageCountsController.stream
          .map<int>((e) => e.values.fold(0, (p, e) => p + e));

  @override
  Future<void> reportUser({
    required String uid,
    required String reportedUid,
    required String reason,
    String? extra,
  }) =>
      _rawUsersApi.reportUser(
        uid: uid,
        reportedUid: reportedUid,
        reason: reason,
        extra: extra,
      );

  @override
  Future<void> contactUs({required String uid, required String message}) =>
      _rawUsersApi.contactUs(
        uid: uid,
        message: message,
      );

  void _clearCache() {
    _publicProfile = null;
    _privateProfile = null;
    _friendsPreferences = null;
    _datingPreferences = null;
    _profileStateController.state = null;
  }
}
