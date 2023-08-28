import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/online_users_provider.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';

// Stays alive and initializes providers.
// TODO: Find a cleaner way of initializing and keeping alive providers
class ProviderWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const ProviderWatcher({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ProviderWatcher> createState() => _ProviderWatcherState();
}

class _ProviderWatcherState extends ConsumerState<ProviderWatcher> {
  @override
  void initState() {
    super.initState();
    // Informs the backend of online/offline/logout
    ref.listenManual(onlineUsersProvider, (_, __) => {});
  }

  @override
  Widget build(BuildContext context) {
    // Initialize providers
    ref.watch(dynamicConfigProvider);
    ref.watch(dynamicConfigStateProvider);
    return widget.child;
  }
}
