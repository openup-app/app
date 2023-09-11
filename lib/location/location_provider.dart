import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/util/key_value_store_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

part 'location_provider.freezed.dart';

final locationMessageProvider = StateProvider<LocationMessage?>((ref) => null);

enum LocationMessage { permissionRationale }

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final latLongOverride = ref.watch(userProvider2.select<LatLong?>((p) {
    return p.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn.account.profile.latLongOverride,
    );
  }));
  final locationNotifier = LocationNotifier(
    keyValueStore: ref.read(keyValueStoreProvider),
    onMessage: (message) =>
        ref.read(locationMessageProvider.notifier).state = message,
    onUpdateLocation: (latLong) => _updateLocationIfSignedIn(latLong, ref),
    latLongOverride: latLongOverride,
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
  final LatLong? latLongOverride;

  LocationNotifier({
    required this.keyValueStore,
    required this.onMessage,
    required this.onUpdateLocation,
    this.latLongOverride,
  }) : super(
          LocationState(
            initialLatLong: _readInitialLatLong(keyValueStore),
            current: _readInitialLatLong(keyValueStore),
          ),
        );

  Future<LocationState?> retryInitLocation() => _initLocation();

  LatLong get _current => state.current;

  Future<LocationState?> _initLocation() async {
    final service = LocationService();
    final hasPermission = await _requestLocationPermission(service);
    if (!mounted) {
      return null;
    }

    if (hasPermission) {
      final location = await service.getLatLong();
      if (!mounted) {
        return null;
      }
      location.map(
        value: (value) => _update(latLongOverride ?? value.latLong),
        denied: (_) => onMessage(LocationMessage.permissionRationale),
        failure: (_) {},
      );
      return state;
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
      const austinHighSchool = LatLong(
        latitude: 30.273729565067256,
        longitude: -97.76676369414457,
      );
      return austinHighSchool;
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

double distanceMiles(LatLong a, LatLong b) {
  const double earthRadiusMiles = 3958.8;

  double aLatAngle = radians(a.latitude);
  double aLonAngle = radians(a.longitude);
  double bLatAngle = radians(b.latitude);
  double bLonAngle = radians(b.longitude);

  double deltaLatAngle = bLatAngle - aLatAngle;
  double deltaLonAngle = bLonAngle - aLonAngle;

  double squared = sin(deltaLatAngle / 2) * sin(deltaLatAngle / 2) +
      cos(aLatAngle) *
          cos(bLatAngle) *
          sin(deltaLonAngle / 2) *
          sin(deltaLonAngle / 2);
  double angularDist = 2 * atan2(sqrt(squared), sqrt(1 - squared));
  double distanceMiles = earthRadiusMiles * angularDist;

  return distanceMiles;
}
