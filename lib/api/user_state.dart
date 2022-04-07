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

  void uid(String uid) => state = state.copyWith(uid: uid);

  void profile(Profile profile) => state = state.copyWith(profile: profile);

  void attributes(Attributes attributes) =>
      state = state.copyWith(attributes: attributes);

  void attributes2(Attributes2 attributes) =>
      state = state.copyWith(attributes2: attributes);

  void friendsPreferences(Preferences preferences) =>
      state = state.copyWith(friendsPreferences: preferences);

  void datingPreferences(Preferences preferences) =>
      state = state.copyWith(datingPreferences: preferences);

  void unreadMessageCount(Map<String, int> unreadMessageCount) =>
      state = state.copyWith(unreadMessageCount: unreadMessageCount);

  UserState get userState => state;
}

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default('') String uid,
    @Default(null) Profile? profile,
    @Default(null) Attributes? attributes,
    @Default(null) Attributes2? attributes2,
    @Default(null) Preferences? friendsPreferences,
    @Default(null) Preferences? datingPreferences,
    @Default({}) Map<String, int> unreadMessageCount,
  }) = _UserState;
}
