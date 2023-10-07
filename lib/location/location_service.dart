import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:location/location.dart' as loc;
import 'package:location/location.dart' hide Location;
import 'package:openup/api/api.dart';
import 'package:vector_math/vector_math_64.dart';

part 'location_service.freezed.dart';

final locationServiceProvider =
    Provider<LocationService>((ref) => throw 'Uninitialized provider');

class LocationService {
  final _location = loc.Location();

  LocationService();

  Future<bool> hasPermission() async {
    final status = await _location.hasPermission();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited;
  }

  Future<bool> requestPermission() async {
    final status = await _location.requestPermission();
    return status == PermissionStatus.granted ||
        status == PermissionStatus.grantedLimited;
  }

  Future<LocationStatus> getLatLong() async {
    if (!await hasPermission()) {
      if (!await requestPermission()) {
        return const _LocationFailure();
      }
    }

    if (!await hasPermission()) {
      if (!await requestPermission()) {
        return const _LocationDenied();
      }
    }

    try {
      final data = await _location.getLocation();
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (latitude == null || longitude == null) {
        return const _LocationFailure();
      }
      return LocationValue(
        LatLong(
          latitude: latitude,
          longitude: longitude,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      return const _LocationFailure();
    }
  }
}

@freezed
class LocationStatus with _$LocationStatus {
  const factory LocationStatus.value(LatLong latLong) = LocationValue;

  const factory LocationStatus.denied() = _LocationDenied;

  const factory LocationStatus.failure() = _LocationFailure;
}

double greatCircleDistance(LatLong latLong1, LatLong latLong2) {
  // Haversine
  final lat1 = radians(latLong1.latitude);
  final long1 = radians(latLong1.longitude);
  final lat2 = radians(latLong2.latitude);
  final long2 = radians(latLong2.longitude);
  const earthRadiusMeters = 6378137;
  return earthRadiusMeters *
      acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long2 - long1));
}
