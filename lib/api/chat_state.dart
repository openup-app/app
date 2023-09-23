import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';

final unreadCountProvider =
    StateNotifierProvider<UnreadCountStateNotifier, int>(
  (ref) {
    final chatrooms = ref.watch(userProvider.select((p) {
      return p.map(
        guest: (_) => <Chatroom>[],
        signedIn: (signedIn) => signedIn.chatrooms ?? <Chatroom>[],
      );
    }));
    return UnreadCountStateNotifier(chatrooms);
  },
  dependencies: [userProvider],
);

class UnreadCountStateNotifier extends StateNotifier<int> {
  UnreadCountStateNotifier(List<Chatroom> chatrooms)
      : super(_chatroomsToUnread(chatrooms));

  void updateUnreadCount(int count) => state = count;

  void updateUnroadCountWithChatrooms(List<Chatroom> chatrooms) =>
      state = _chatroomsToUnread(chatrooms);
}

int _chatroomsToUnread(List<Chatroom> chatrooms) =>
    chatrooms.fold(0, (p, e) => p + e.unreadCount);
