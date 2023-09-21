import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/location/mapbox_location_search_service.dart';

abstract class LocationSearchService {
  Future<Either<LocationSearchError, List<LocationSearchResult>>> search(
      LocationSearch query);
  Future<Either<LocationSearchError, LatLong>> latLongForResult(
      LocationSearchResult result);
}

class LocationSearch {
  final String text;
  final LatLong? proximity;

  LocationSearch(this.text, [this.proximity]);
}

enum LocationSearchError { clientError, networkError, serverError }

final locationSearchProvider =
    Provider<LocationSearchService>((ref) => throw 'Uninitialized provider');
