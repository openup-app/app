import 'package:flutter/foundation.dart';
import 'package:location/location.dart';

class LocationService {
  const LocationService();

  Future<LatLong?> getLatLong() async {
    final location = Location();
    if (!await location.serviceEnabled()) {
      if (!await location.requestService()) {
        return null;
      }
    }

    var permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted ||
          permission != PermissionStatus.grantedLimited) {
        return null;
      }
    } else if (permission == PermissionStatus.deniedForever) {
      return null;
    }

    try {
      final data = await location.getLocation();
      final latitude = data.latitude;
      final longitude = data.longitude;
      if (latitude == null || longitude == null) {
        return null;
      }
      return LatLong(latitude, longitude);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}

class LatLong {
  final double latitude;
  final double longitude;

  LatLong(this.latitude, this.longitude);
}
