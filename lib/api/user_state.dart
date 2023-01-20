import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';

part 'user_state.freezed.dart';

final userProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier();
});

class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier() : super(const UserState());

  void uid(String uid) => state = state.copyWith(uid: uid);

  void profile(Profile profile) => state = state.copyWith(profile: profile);

  void collections(List<Collection> collections) =>
      state = state.copyWith(collections: collections);

  UserState get userState => state;
}

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default('') String uid,
    @Default(null) Profile? profile,
    @Default(<Collection>[]) List<Collection> collections,
  }) = _UserState;
}
