import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:openup/api/api.dart';
import 'package:http/http.dart' as http;
import 'package:openup/location/location_search.dart';
import 'package:uuid/uuid.dart';

class MapboxLocationSearchService implements LocationSearchService {
  static const _uuid = Uuid();

  final String _accessToken;

  String _sessionToken = '';
  DateTime? _sessionTokenTime;

  MapboxLocationSearchService({
    required String accessToken,
  }) : _accessToken = accessToken;

  @override
  Future<Either<LocationSearchError, List<LocationSearchResult>>> search(
      LocationSearch query) {
    _maybeRegenerateSessionToken();
    return _mapboxSuggest(query);
  }

  @override
  Future<Either<LocationSearchError, LatLong>> latLongForResult(
      LocationSearchResult result) async {
    _maybeRegenerateSessionToken();
    final retrieveResult = await _mapboxRetrieve(result.id);
    retrieveResult.fold(
      (l) {},
      (r) => _generateSessionToken(),
    );
    return retrieveResult;
  }

  void _generateSessionToken() {
    _sessionToken = _uuid.v4();
    _sessionTokenTime = DateTime.now();
  }

  void _maybeRegenerateSessionToken() {
    // Sessions expire every 60 minutes
    final sessionTokenTime = _sessionTokenTime;
    if (sessionTokenTime == null ||
        DateTime.now().difference(sessionTokenTime) >=
            const Duration(hours: 1)) {
      _generateSessionToken();
    }
  }

  Future<Either<LocationSearchError, List<LocationSearchResult>>>
      _mapboxSuggest(LocationSearch query) async {
    final text = query.text.substring(0, min(query.text.length, 256));
    final latLong = query.proximity;
    final proximityQuery =
        latLong == null ? null : '${latLong.longitude},${latLong.latitude}';

    return _request(
      makeRequest: () => http.get(
        Uri.parse(
            'https://api.mapbox.com/search/searchbox/v1/suggest?q=$text${proximityQuery == null ? '' : '&proximity=$proximityQuery'}&session_token=$_sessionToken&access_token=$_accessToken'),
        headers: {'Content-Type': 'application/json'},
      ),
      handleSuccess: (response) =>
          Right(_parseMapboxSearchResponse(response.body)),
    );
  }

  Future<Either<LocationSearchError, LatLong>> _mapboxRetrieve(
      String id) async {
    return _request(
      makeRequest: () => http.get(
        Uri.parse(
            'https://api.mapbox.com/search/searchbox/v1/retrieve/$id?session_token=$_sessionToken&access_token=$_accessToken'),
        headers: {'Content-Type': 'application/json'},
      ),
      handleSuccess: (response) =>
          Right(_parseMapboxRetrieveResponse(response.body)),
    );
  }

  List<LocationSearchResult> _parseMapboxSearchResponse(String body) {
    final result = jsonDecode(body);
    final predictions = result['suggestions'] as List<dynamic>;
    return predictions.map((p) {
      final mapboxId = p['mapbox_id'];
      final name = p['name'];
      final fullAddress = p['full_address'];
      final placeFormatted = p['place_formatted'];
      return LocationSearchResult(
        mapboxId,
        name,
        fullAddress ?? placeFormatted,
      );
    }).toList();
  }

  LatLong _parseMapboxRetrieveResponse(String body) {
    final result = jsonDecode(body);
    final features = result['features'];
    final feature = features[0];
    final properties = feature['properties'];
    final coordinates = properties['coordinates'];
    final latitude = coordinates['latitude'];
    final longitude = coordinates['longitude'];
    return LatLong(latitude: latitude, longitude: longitude);
  }

  Future<Either<LocationSearchError, T>> _request<T>({
    required Future<http.Response> Function() makeRequest,
    required Either<LocationSearchError, T> Function(http.Response response)
        handleSuccess,
  }) async {
    try {
      final response = await makeRequest();
      final statusCode = response.statusCode;
      if (response.statusCode == 200) {
        return handleSuccess(response);
      } else if (statusCode >= 400 && statusCode < 500) {
        return const Left(LocationSearchError.clientError);
      } else if (statusCode >= 500 && statusCode < 600) {
        return const Left(LocationSearchError.serverError);
      } else {
        throw response;
      }
    } on SocketException catch (_) {
      return const Left(LocationSearchError.networkError);
    } catch (e) {
      rethrow;
    }
  }
}

class LocationSearchResult {
  final String id;
  final String name;
  final String? address;

  LocationSearchResult(this.id, this.name, this.address);
}
