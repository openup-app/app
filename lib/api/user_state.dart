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

  void update(UserState state) => this.state = state;

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
