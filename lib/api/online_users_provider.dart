import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/online_users_api.dart';
import 'package:openup/auth/auth_provider.dart';

part 'online_users_provider.freezed.dart';

final onlineUsersProvider =
    StateNotifierProvider.autoDispose<OnlineUsersStateNotifier, OnlineUsers>(
        (ref) {
  const host = String.fromEnvironment('HOST');
  const socketPort = 8081;

  OnlineUsersApi? onlineUsersApi;

  final notifier = OnlineUsersStateNotifier(
    onSubscribe: (uid) => onlineUsersApi?.subscribeToOnlineStatus(uid),
    onUnsubscribe: (uid) => onlineUsersApi?.unsubscribeToOnlineStatus(uid),
  );

  ref.listen<String?>(
    authProvider.select((p) {
      return p.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn.token,
      );
    }),
    (previous, next) {
      onlineUsersApi = OnlineUsersApi(
        host: host,
        port: socketPort,
        authToken: next,
        onConnectionError: () {},
        onOnlineStatusChanged: notifier._onlineChanged,
      );
    },
    fireImmediately: true,
  );

  ref.onDispose(() {
    onlineUsersApi?.dispose();
  });

  return notifier;
});

class OnlineUsersStateNotifier extends StateNotifier<OnlineUsers> {
  final void Function(String uid) onSubscribe;
  final void Function(String uid) onUnsubscribe;

  OnlineUsersStateNotifier({
    required this.onSubscribe,
    required this.onUnsubscribe,
  }) : super(const OnlineUsers());

  void _onlineChanged(String uid, bool online) {
    if (online) {
      state = state.copyWith(set: Set.of(state.set)..add(uid));
    } else {
      state = state.copyWith(set: Set.of(state.set)..remove(uid));
    }
  }

  void subscribe(String uid) => onSubscribe(uid);

  void unsubscribe(String uid) => onUnsubscribe(uid);
}

@freezed
class OnlineUsers with _$OnlineUsers {
  const OnlineUsers._();

  const factory OnlineUsers({
    @Default({}) Set<String> set,
  }) = _OnlineUsers;

  bool isOnline(String uid) => set.contains(uid);
}
