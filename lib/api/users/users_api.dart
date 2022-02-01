import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/account.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/raw_users_api.dart';
import 'package:openup/api/users/rekindle.dart';
import 'package:openup/api/users/user_metadata.dart';
import 'package:rxdart/subjects.dart';

late Provider<UsersApi> usersApiProvider;
late StateProvider<PublicProfile?> profileProvider;

late StateController<PublicProfile?> _profileStateController;

void initUsersApi({
  required String host,
  required int port,
  required String authToken,
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
  Account? _account;
  UserMetadata? _userMetadata;
  PublicProfile? _publicProfile;
  PrivateProfile? _privateProfile;
  Preferences? _friendsPreferences;
  Preferences? _datingPreferences;
  Timer? _countRequestDebounce;
  Map<String, int> _unreadChatMessageCounts = {};
  final _unreadChatMessageCountsController =
      BehaviorSubject<Map<String, int>>();

  UsersApi({
    required String host,
    required int port,
    required String authToken,
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
  Future<void> createUserWithEmail({
    required String email,
    required String password,
    required DateTime birthday,
  }) async {
    await _rawUsersApi.createUserWithEmail(
      email: email,
      password: password,
      birthday: birthday,
    );
    _clearCache();
  }

  @override
  Future<void> createUserWithUid({
    required String uid,
    required DateTime birthday,
    required String? notificationToken,
  }) async {
    await _rawUsersApi.createUserWithUid(
      uid: uid,
      birthday: birthday,
      notificationToken: notificationToken,
    );
    _clearCache();
  }

  @override
  Future<bool> checkBirthday({
    required String phone,
    required DateTime birthday,
  }) =>
      _rawUsersApi.checkBirthday(phone: phone, birthday: birthday);

  @override
  Future<Account> getAccount(String uid) async {
    final account = await _rawUsersApi.getAccount(uid);
    if (uid == _uid) {
      _account = account;
    }
    return account;
  }

  @override
  Future<void> updateAccount(String uid, Account account) {
    if (uid == _uid) {
      _account = account;
    }
    return _rawUsersApi.updateAccount(uid, account);
  }

  @override
  Future<void> updateUserMetadata(String uid, UserMetadata userMetadata) {
    if (uid == _uid) {
      _userMetadata = userMetadata;
    }
    return _rawUsersApi.updateUserMetadata(uid, userMetadata);
  }

  @override
  Future<UserMetadata> getUserMetadata(String uid) async {
    if (uid == _uid && _userMetadata != null) {
      return _userMetadata!;
    }

    final userMetadata = await _rawUsersApi.getUserMetadata(uid);
    if (uid == _uid) {
      _userMetadata = userMetadata;
    }
    return userMetadata;
  }

  @override
  Future<PublicProfile> getPublicProfile(String uid) async {
    if (uid == _uid && _publicProfile != null) {
      return _publicProfile!;
    }

    final publicProfile = await _rawUsersApi.getPublicProfile(uid);
    if (uid == _uid) {
      _publicProfile = publicProfile;
      _profileStateController.state = _publicProfile;
    }
    return publicProfile;
  }

  @override
  Future<void> updatePublicProfile(String uid, PublicProfile profile) {
    if (uid == _uid) {
      _publicProfile = profile;
      _profileStateController.state = _publicProfile;
    }
    return _rawUsersApi.updatePublicProfile(uid, profile);
  }

  @override
  Future<PrivateProfile> getPrivateProfile(String uid) async {
    if (uid == _uid && _privateProfile != null) {
      return _privateProfile!;
    }

    final privateProfile = await _rawUsersApi.getPrivateProfile(uid);
    if (uid == _uid) {
      _privateProfile = privateProfile;
    }
    return privateProfile;
  }

  @override
  Future<void> updatePrivateProfile(String uid, PrivateProfile profile) {
    _privateProfile = profile;
    return _rawUsersApi.updatePrivateProfile(uid, profile);
  }

  @override
  Future<String> updateGalleryPhoto(
    String uid,
    Uint8List photo,
    int index,
  ) async {
    final url = await _rawUsersApi.updateGalleryPhoto(uid, photo, index);
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
  Future<void> deleteGalleryPhoto(String uid, int index) async {
    await _rawUsersApi.deleteGalleryPhoto(uid, index);
    final gallery = List<String>.of(_publicProfile?.gallery ?? []);
    gallery.removeAt(index);
    _publicProfile = _publicProfile?.copyWith(gallery: gallery);
    _profileStateController.state = _publicProfile;
  }

  @override
  Future<String> updateAudioBio(String uid, Uint8List audio) async {
    final url = await _rawUsersApi.updateAudioBio(uid, audio);
    _publicProfile = _publicProfile?.copyWith(audio: url);
    _profileStateController.state = _publicProfile;
    return url;
  }

  @override
  Future<void> deleteAudioBio(String uid) async {
    await _rawUsersApi.deleteAudioBio(uid);
    _publicProfile = _publicProfile?.copyWith(audio: null);
    _profileStateController.state = _publicProfile;
  }

  @override
  Future<void> deleteUser(String uid) async {
    await _rawUsersApi.deleteUser(uid);
    _clearCache();
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
  Future<int> getPossibleFriendCount(
    String uid,
    Preferences preferences,
  ) async {
    final completer = Completer<int>();
    _countRequestDebounce?.cancel();
    _countRequestDebounce = Timer(const Duration(seconds: 2), () async {
      final count = await _rawUsersApi.getPossibleFriendCount(uid, preferences);
      completer.complete(count);
    });
    return completer.future;
  }

  @override
  Future<int> getPossibleDateCount(String uid, Preferences preferences) async {
    final completer = Completer<int>();
    _countRequestDebounce?.cancel();
    _countRequestDebounce = Timer(const Duration(seconds: 2), () async {
      final count = await _rawUsersApi.getPossibleDateCount(uid, preferences);
      completer.complete(count);
    });
    return completer.future;
  }

  @override
  Future<List<Rekindle>> getRekindleList(String uid) =>
      _rawUsersApi.getRekindleList(uid);

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
    String uid,
    String calleeUid,
    bool video, {
    bool group = false,
  }) =>
      _rawUsersApi.call(uid, calleeUid, video, group: group);

  @override
  Future<Map<String, int>> getAllChatroomUnreadCounts(String uid) async {
    final counts = await _rawUsersApi.getAllChatroomUnreadCounts(uid);
    _unreadChatMessageCounts = counts;
    _unreadChatMessageCountsController.add(_unreadChatMessageCounts);
    return counts;
  }

  @override
  Future<void> updateNotificationToken(String uid, String notificationToken) =>
      _rawUsersApi.updateNotificationToken(uid, notificationToken);

  UserMetadata? get userMetadata => _userMetadata;

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

  void _clearCache() {
    _account = null;
    _publicProfile = null;
    _privateProfile = null;
    _friendsPreferences = null;
    _datingPreferences = null;
    _profileStateController.state = null;
  }
}
