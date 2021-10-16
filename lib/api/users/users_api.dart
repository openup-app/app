import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/account.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/raw_users_api.dart';

late final Provider<UsersApi> usersApiProvider;
late final StateProvider<PublicProfile?> profileProvider;
late final StateController<PublicProfile?> _profileStateController;

void initUsersApi({required String host}) {
  profileProvider = StateProvider<PublicProfile?>((ref) {
    return null;
  });
  usersApiProvider = Provider<UsersApi>((ref) {
    _profileStateController = ref.read(profileProvider);
    return UsersApi(host: host);
  });
}

class UsersApi implements RawUsersApi {
  final RawUsersApi _rawUsersApi;
  Account? _account;
  PublicProfile? _publicProfile;
  PrivateProfile? _privateProfile;
  Preferences? _friendsPreferences;
  Preferences? _datingPreferences;
  Timer? _countRequestDebounce;

  UsersApi({required String host}) : _rawUsersApi = RawUsersApi(host: host);

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
  }) async {
    await _rawUsersApi.createUserWithUid(uid: uid, birthday: birthday);
    _clearCache();
  }

  @override
  Future<Account> getAccount(String uid) async {
    _account ??= await _rawUsersApi.getAccount(uid);
    return _account!;
  }

  @override
  Future<void> updateAccount(String uid, Account account) {
    _account = account;
    return _rawUsersApi.updateAccount(uid, account);
  }

  @override
  Future<PublicProfile> getPublicProfile(String uid) async {
    _publicProfile ??= await _rawUsersApi.getPublicProfile(uid);
    _profileStateController.state = _publicProfile;
    return _publicProfile!;
  }

  @override
  Future<void> updatePublicProfile(String uid, PublicProfile profile) {
    _publicProfile = profile;
    _profileStateController.state = _publicProfile;
    return _rawUsersApi.updatePublicProfile(uid, profile);
  }

  @override
  Future<PrivateProfile> getPrivateProfile(String uid) async {
    _privateProfile ??= await _rawUsersApi.getPrivateProfile(uid);
    return _privateProfile!;
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

  PublicProfile? get publicProfile => _publicProfile;

  void _clearCache() {
    _account = null;
    _publicProfile = null;
    _privateProfile = null;
    _friendsPreferences = null;
    _datingPreferences = null;
    _profileStateController.state = null;
  }
}
