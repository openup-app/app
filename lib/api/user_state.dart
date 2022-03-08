import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';

part 'user_state.freezed.dart';

final userProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier();
});

class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier() : super(const UserState());

  void uid(String uid) => state.copyWith(uid: uid);

  void profile(Profile profile) => state.copyWith(profile: profile);

  void attributes(Attributes attributes) =>
      state.copyWith(attributes: attributes);

  void friendsPreferences(Preferences preferences) =>
      state.copyWith(friendsPreferences: preferences);

  void datingPreferences(Preferences preferences) =>
      state.copyWith(datingPreferences: preferences);

  void unreadMessageCount(Map<String, int> unreadMessageCount) =>
      state.copyWith(unreadMessageCount: unreadMessageCount);

  UserState get userState => state;
}

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default('') String uid,
    @Default(null) Profile? profile,
    @Default(null) Attributes? attributes,
    @Default(null) Preferences? friendsPreferences,
    @Default(null) Preferences? datingPreferences,
    @Default({}) Map<String, int> unreadMessageCount,
  }) = _UserState;
}
