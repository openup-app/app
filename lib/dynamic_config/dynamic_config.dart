import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';

final dynamicConfigProvider =
    StateNotifierProvider<DynamicConfigStateNotifier, DynamicConfig>((ref) {
  final api = ref.watch(apiProvider);
  return DynamicConfigStateNotifier(api: api);
});

class DynamicConfigStateNotifier extends StateNotifier<DynamicConfig> {
  final Api api;
  DynamicConfigStateNotifier({
    required this.api,
  }) : super(const DynamicConfig()) {
    _init();
  }

  void _init() async {
    final result = await api.getDynamicConfiguration();
    if (!mounted) {
      return;
    }

    result.fold(
      (_) {},
      (r) => state = r,
    );
  }
}
