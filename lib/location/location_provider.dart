import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/util/key_value_store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'location_provider.freezed.dart';

final locationMessageProvider = StateProvider<LocationMessage?>((ref) => null);

enum LocationMessage { permissionRationale }

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationNotifier = LocationNotifier(
    keyValueStore: ref.read(keyValueStoreProvider),
    onMessage: (message) =>
        ref.read(locationMessageProvider.notifier).state = message,
    onUpdateLocation: (latLong) => _updateLocationIfSignedIn(latLong, ref),
  );

  locationNotifier._initLocation();

  // Update location when signed in
  _updateLocationIfSignedIn(locationNotifier._current, ref);

  return locationNotifier;
});

void _updateLocationIfSignedIn(LatLong latLong,
    StateNotifierProviderRef<LocationNotifier, LocationState> ref) {
  final signedIn = ref.watch(userProvider2.select((p) {
    return p.map(
      guest: (_) => false,
      signedIn: (_) => true,
    );
  }));
  if (signedIn) {
    ref.read(apiProvider).updateLocation(latLong);
  }
}

Future<bool> _requestLocationPermission(LocationService service) async {
  final hasPermission = await service.hasPermission();
  if (hasPermission) {
    return true;
  }

  return await service.requestPermission();
}

class LocationNotifier extends StateNotifier<LocationState> {
  static const _initialLocationKey = 'initial_location';

  final SharedPreferences keyValueStore;
  final void Function(LocationMessage message) onMessage;
  final void Function(LatLong latLong) onUpdateLocation;

  LocationNotifier({
    required this.keyValueStore,
    required this.onMessage,
    required this.onUpdateLocation,
  }) : super(
          LocationState(
            initialLatLong: _readInitialLatLong(keyValueStore),
            current: _readInitialLatLong(keyValueStore),
          ),
        );

  void retryInitLocation() => _initLocation();

  LatLong get _current => state.current;

  void _initLocation() async {
    final service = LocationService();
    if (await _requestLocationPermission(service)) {
      final location = await service.getLatLong();
      if (!mounted) {
        return;
      }
      location.map(
        value: (value) => _update(value.latLong),
        denied: (_) => onMessage(LocationMessage.permissionRationale),
        failure: (_) {},
      );
    } else {
      onMessage(LocationMessage.permissionRationale);
    }
  }

  void _update(LatLong latLong) {
    onUpdateLocation(latLong);

    keyValueStore.setString(
      _initialLocationKey,
      jsonEncode(latLong.toJson()),
    );

    state = state.copyWith(current: latLong);
  }

  static LatLong _readInitialLatLong(SharedPreferences keyValueStore) {
    final initialLatLongJson = keyValueStore.getString(_initialLocationKey);
    if (initialLatLongJson == null) {
      const fortWorth = LatLong(
        latitude: 32.735747,
        longitude: -97.326995,
      );
      return fortWorth;
    }
    return LatLong.fromJson(jsonDecode(initialLatLongJson));
  }
}

@freezed
class LocationState with _$LocationState {
  const factory LocationState({
    required LatLong initialLatLong,
    required LatLong current,
  }) = _LocationState;
}
