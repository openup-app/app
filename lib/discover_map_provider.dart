import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/util/key_value_store_service.dart';

final showSafetyNoticeProvider = StateProvider<bool>((ref) {
  const safetyNoticeShownKey = 'safety_notice_shown';
  final keyValueStore = ref.read(keyValueStoreProvider);
  final shown = keyValueStore.getBool(safetyNoticeShownKey) ?? false;
  if (shown) {
    return false;
  }

  keyValueStore.setBool(safetyNoticeShownKey, true);
  return true;
});
