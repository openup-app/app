import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/auth/auth_provider.dart';

part 'online_users_api_util.freezed.dart';

final onlineUsersApiProvider =
    Provider<OnlineUsersApi>((ref) => throw 'OnlineUsersApi is uninitialized');

final onlineUsersProvider =
    StateNotifierProvider.autoDispose<OnlineUsersStateNotifier, OnlineUsers>(
        (ref) {
  final onlineUsersApi = ref.read(onlineUsersApiProvider);
  final uidProvider = authProvider.select((p) {
    return p.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn.uid,
    );
  });
  ref.listen<String?>(
    uidProvider,
    (prev, curr) {
      if (curr != null) {
        onlineUsersApi.setOnline(curr, true);
      } else {
        if (prev != null) {
          onlineUsersApi.setOnline(prev, false);
        }
      }
    },
    fireImmediately: true,
  );

  ref.onDispose(onlineUsersApi.dispose);

  return OnlineUsersStateNotifier();
});

class OnlineUsersStateNotifier extends StateNotifier<OnlineUsers> {
  OnlineUsersStateNotifier() : super(const OnlineUsers({}));

  void onlineChanged(String uid, bool online) {
    if (online) {
      state = state.copyWith(set: Set.of(state.set)..add(uid));
    } else {
      state = state.copyWith(set: Set.of(state.set)..remove(uid));
    }
  }
}

@freezed
class OnlineUsers with _$OnlineUsers {
  const OnlineUsers._();

  const factory OnlineUsers(Set<String> set) = _OnlineUsers;

  bool isOnline(String uid) => set.contains(uid);
}
