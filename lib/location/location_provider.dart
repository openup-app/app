import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'location_provider.freezed.dart';

final locationMessageProvider = StateProvider<LocationMessage?>((ref) => null);

enum LocationMessage { permissionRationale }

final locationOverrideProvider = StateProvider<LatLong?>((ref) {
  return ref.watch(userProvider.select((s) {
    return s.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn.account.profile.latLongOverride,
    );
  }));
});

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  throw 'Uninitialized provider';
});

class LocationNotifier extends StateNotifier<LocationState> {
  static const _kKeyLastKnownLatLong = 'lastKnownLocation';
  final LocationService _service;
  final SharedPreferences _keyValueStore;
  final LatLong? _overrideLatLong;

  LocationNotifier({
    required LocationService service,
    required SharedPreferences keyValueStore,
    required LatLong fallbackInitialLatLong,
    LatLong? overrideLatLong,
  })  : _service = service,
        _keyValueStore = keyValueStore,
        _overrideLatLong = overrideLatLong,
        super(LocationState(
            current: _loadLastKnownLatLong(keyValueStore) ??
                fallbackInitialLatLong)) {
    _init();
  }

  void _init() async {
    final status = await _service.getLatLong();
    if (!mounted) {
      return;
    }

    _updateStateWithStatus(status);
  }

  void _updateStateWithStatus(LocationStatus status) {
    final newLatLong = status.map(
      denied: (_) => null,
      failure: (_) => null,
      value: (value) => value.latLong,
    );
    if (newLatLong != null) {
      _saveLastKnownLatLong(_keyValueStore, newLatLong);
    }
    state = state.copyWith(
      status: status,
      current: newLatLong ?? _overrideLatLong ?? state.current,
    );
  }

  void updateLocationWithoutRequest() async {
    final status = await _service.getLatLong();
    if (!mounted) {
      return;
    }
    _updateStateWithStatus(status);
  }

  void updateLocationWithRequest() async {
    await _service.requestPermission();
    updateLocationWithoutRequest();
  }

  static LatLong? _loadLastKnownLatLong(SharedPreferences keyValueStore) {
    final lastKnownLocationString =
        keyValueStore.getString(_kKeyLastKnownLatLong) ?? '{}';
    final lastKnownLocationJson = jsonDecode(lastKnownLocationString);
    try {
      return LatLong.fromJson(lastKnownLocationJson);
    } catch (e) {
      return null;
    }
  }

  static void _saveLastKnownLatLong(
      SharedPreferences keyValueStore, LatLong latLong) {
    keyValueStore.setString(
        _kKeyLastKnownLatLong, jsonEncode(latLong.toJson()));
  }
}

@freezed
class LocationState with _$LocationState {
  const factory LocationState({
    @Default(null) LocationStatus? status,
    required LatLong current,
  }) = _LocationState;
}
