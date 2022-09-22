import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:location/location.dart';

part 'location_service.freezed.dart';

class LocationService {
  final _location = Location();

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

  Future<LatLong> getLatLong() async {
    if (!await _location.serviceEnabled()) {
      if (!await _location.requestService()) {
        return const _LatLongFailure();
      }
    }

    if (!await hasPermission()) {
      if (!await requestPermission()) {
        return const _LatLongDenied();
      }
    }

    try {
      final data = await _location.getLocation();
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (latitude == null || longitude == null) {
        return const _LatLongFailure();
      }
      return _LatLongValue(latitude, longitude);
    } catch (e) {
      debugPrint(e.toString());
      return const _LatLongFailure();
    }
  }
}

@freezed
class LatLong with _$LatLong {
  const factory LatLong.value(double latitude, double longitude) =
      _LatLongValue;

  const factory LatLong.denied() = _LatLongDenied;

  const factory LatLong.failure() = _LatLongFailure;
}
