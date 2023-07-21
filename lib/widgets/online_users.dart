import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/online_users_api_util.dart';

// Stays alive and informs the backend of online/offline/logout.
class OnlineUsersWatcher extends ConsumerWidget {
  final Widget child;
  const OnlineUsersWatcher({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(onlineUsersApiProvider);
    return child;
  }
}
