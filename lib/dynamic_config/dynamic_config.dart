import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/dynamic_config/dynamic_config_service.dart';

part 'dynamic_config.freezed.dart';

final dynamicConfigStateProvider = StateNotifierProvider.autoDispose<
    DynamicConfigStateStateNotifier,
    DynamicConfigState>((ref) => throw 'Unimplemented provider');

class DynamicConfigStateStateNotifier
    extends StateNotifier<DynamicConfigState> {
  late final StreamSubscription _streamSubscription;
  final DynamicConfigService _service;

  DynamicConfigStateStateNotifier(this._service)
      : super(DynamicConfigState.loading) {
    _streamSubscription = _service.onChangeStream.listen((_) {
      if (mounted) {
        state = DynamicConfigState.ready;
      }
    });
  }

  void onDispose() => _streamSubscription.cancel();
}

final dynamicConfigProvider =
    StateNotifierProvider<DynamicConfigStateNotifier, DynamicConfig>(
        (ref) => throw 'Unimplemented provider');

class DynamicConfigStateNotifier extends StateNotifier<DynamicConfig> {
  final DynamicConfigService service;

  DynamicConfigStateNotifier(this.service) : super(service.defaults) {
    service.onChangeStream.listen((_) {
      if (!mounted) {
        return;
      }
      _onDynamicConfigChange();
    });
  }

  void _onDynamicConfigChange() => state = service.config;
}

@freezed
class DynamicConfig with _$DynamicConfig {
  const factory DynamicConfig({
    required String contactInviteMessage,
    required bool loginRequired,
  }) = _DynamicConfig;
}

enum DynamicConfigState { loading, ready }
