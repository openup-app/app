import 'dart:math';

import 'package:openup/api/api.dart';
import 'package:vector_math/vector_math_64.dart';

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
