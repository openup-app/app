import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/location/location_search.dart';
import 'package:openup/location/mapbox_location_search_service.dart';

part 'event_create_location_search.freezed.dart';

final eventCreateLocationSearchProvider =
    StateNotifierProvider<_LocationSearchStateNotifier, _LocationSearchState>(
        (ref) {
  return _LocationSearchStateNotifier(
    searchService: ref.read(locationSearchProvider),
    locationNotifier: ref.read(locationProvider.notifier),
  );
});

class _LocationSearchStateNotifier extends StateNotifier<_LocationSearchState> {
  final LocationSearchService _searchService;
  final LocationNotifier _locationNotifier;
  late final _Debounceable<List<LocationSearchResult>?, String>
      _debouncedSearch;

  _LocationSearchStateNotifier({
    required LocationSearchService searchService,
    required LocationNotifier locationNotifier,
  })  : _searchService = searchService,
        _locationNotifier = locationNotifier,
        super(const _None()) {
    _debouncedSearch = _debounce(_performSearch);
  }

  Future<List<LocationSearchResult>?> search(String query) async {
    if (query.isEmpty) {
      return null;
    }
    return _debouncedSearch(query);
  }

  Future<List<LocationSearchResult>?> _performSearch(String query) async {
    final latLong = _locationNotifier.current;
    final result = await _searchService.search(LocationSearch(query, latLong));
    if (!mounted) {
      return null;
    }
    return result.fold(
      (l) => null,
      (r) {
        state = _LocationSearchState.results(results: r);
        return r;
      },
    );
  }

  Future<LatLong?> getLocation(LocationSearchResult result) async {
    return state.map(
      (_) => Future.value(null),
      results: (results) async {
        final latLongResult = await _searchService.latLongForResult(result);
        if (!mounted) {
          return null;
        }

        return latLongResult.fold(
          (l) => null,
          (r) => r,
        );
      },
    );
  }
}

typedef _Debounceable<S, T> = Future<S?> Function(T parameter);

/// Copied from dobounce example on https://api.flutter.dev/flutter/material/Autocomplete-class.html
_Debounceable<S, T> _debounce<S, T>(_Debounceable<S?, T> function) {
  _DebounceTimer? debounceTimer;

  return (T parameter) async {
    if (debounceTimer != null && !debounceTimer!.isCompleted) {
      debounceTimer!.cancel();
    }
    debounceTimer = _DebounceTimer();
    try {
      await debounceTimer!.future;
    } catch (error) {
      if (error is _CancelException) {
        return null;
      }
      rethrow;
    }
    return function(parameter);
  };
}

// A wrapper around Timer used for debouncing.
class _DebounceTimer {
  _DebounceTimer() {
    _timer = Timer(const Duration(milliseconds: 400), _onComplete);
  }

  late final Timer _timer;
  final Completer<void> _completer = Completer<void>();

  void _onComplete() {
    _completer.complete();
  }

  Future<void> get future => _completer.future;

  bool get isCompleted => _completer.isCompleted;

  void cancel() {
    _timer.cancel();
    _completer.completeError(const _CancelException());
  }
}

// An exception indicating that the timer was canceled.
class _CancelException implements Exception {
  const _CancelException();
}

@freezed
class _LocationSearchState with _$_LocationSearchState {
  const factory _LocationSearchState() = _None;
  const factory _LocationSearchState.results({
    @Default([]) List<LocationSearchResult> results,
  }) = _Results;
}
