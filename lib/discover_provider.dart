import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/util/key_value_store_service.dart';

part 'discover_provider.freezed.dart';

final discoverAlertProvider = StateProvider<String?>((ref) => null);

final showSafetyNoticeProvider = StateProvider<bool>((ref) {
  const safetyNoticeShownKey = 'safety_notice_shown';
  final keyValueStore = ref.read(keyValueStoreProvider);
  final shown = keyValueStore.getBool(safetyNoticeShownKey) ?? false;
  if (shown) {
    return false;
  }

  keyValueStore.setBool(safetyNoticeShownKey, true);
  return true;
});

final discoverProvider =
    StateNotifierProvider<DiscoverNotifier, DiscoverState>((ref) {
  final api = ref.read(apiProvider);
  final locationNotifier = ref.read(locationProvider.notifier);
  final alertNotifier = ref.read(discoverAlertProvider.notifier);
  return DiscoverNotifier(
    api: api,
    locationNotifier: locationNotifier,
    onAlert: (message) => alertNotifier.state = message,
  );
});

class DiscoverNotifier extends StateNotifier<DiscoverState> {
  final Api api;
  final LocationNotifier locationNotifier;
  final void Function(String message) onAlert;

  CancelableOperation<Either<ApiError, List<Event>>>? _discoverOperation;
  Location? _mapLocation;
  Location? _prevQueryLocation;
  String? _selectIdWhenAvailable;

  DiscoverNotifier({
    required this.api,
    required this.locationNotifier,
    required this.onAlert,
  }) : super(const _Init()) {
    _autoInit();
  }

  void _autoInit() async {
    final locationState = await locationNotifier.retryInitLocation();
    if (mounted && locationState != null) {
      locationChanged(
        Location(
          latLong: locationState.current,
          radius: 20,
        ),
      );
    }
  }

  Future<void> performQuery() async {
    final readyState = _readyState();
    if (readyState == null) {
      return Future.value();
    }

    final location = _mapLocation;
    if (location != null) {
      _prevQueryLocation = location;
      state = readyState.copyWith(selectedEvent: null);
      return _queryEventsAt(location.copyWith(radius: location.radius * 0.5));
    }
    return Future.value();
  }

  Future<void> _queryEventsAt(Location location) async {
    var readyState = _readyState();
    if (readyState == null) {
      return Future.value();
    }
    state = readyState.copyWith(loading: true);
    _discoverOperation?.cancel();
    final discoverFuture = api.getEvents(
      location,
    );
    _discoverOperation = CancelableOperation.fromFuture(discoverFuture);
    final events = await _discoverOperation?.value;

    readyState = _readyState();
    if (!mounted || readyState == null) {
      return;
    }

    readyState = readyState.copyWith(loading: false);
    state = readyState;
    if (events == null) {
      return;
    }

    events.fold(
      (l) {
        var message = errorToMessage(l);
        message = l.when(
          network: (_) => message,
          client: (client) => client.when(
            badRequest: () => 'Unable to request users',
            unauthorized: () => message,
            notFound: () => 'Unable to find users',
            forbidden: () => message,
            conflict: () => message,
          ),
          server: (_) => message,
        );
        onAlert(message);
      },
      (r) {
        Event? eventToSelect;
        final targetId = _selectIdWhenAvailable;
        if (targetId != null) {
          eventToSelect = r.firstWhereOrNull((e) => e.id == targetId);
        }
        _selectIdWhenAvailable = null;
        state = readyState!.copyWith(
          selectedEvent: eventToSelect,
          events: r,
        );
      },
    );
  }

  void locationChanged(Location location) {
    if (_mapLocation == null) {
      state = const DiscoverState.ready(
        loading: false,
        showDebugUsers: false,
        gender: null,
        events: [],
        selectedEvent: null,
      );
    }

    _mapLocation = location.copyWith(radius: location.radius);
    final prevQueryLocation = _prevQueryLocation;
    if (prevQueryLocation == null ||
        _areLocationsDistant(location, prevQueryLocation)) {
      performQuery();
    }
  }

  void genderChanged(Gender? gender) {
    final readyState = _readyState();
    if (readyState != null) {
      state = readyState.copyWith(
        gender: gender,
        events: [],
        selectedEvent: null,
      );
    }
  }

  void selectEvent(Event? event) {
    final readyState = _readyState();
    if (readyState != null) {
      state = readyState.copyWith(
        loading: false,
        selectedEvent: event,
      );
      _discoverOperation?.cancel();
    }
  }

  void userBlocked(String uid) {}

  void idToSelectWhenAvailable(String? id) {
    _selectIdWhenAvailable = id;
    final targetId = _selectIdWhenAvailable;
    final readyState = _readyState();
    if (readyState != null && targetId != null) {
      final event = readyState.events.firstWhereOrNull((e) => e.id == targetId);
      if (event != null) {
        state = readyState.copyWith(selectedEvent: event);
      }
    }
  }

  set showDebugUsers(bool value) {
    final readyState = _readyState();
    if (readyState != null) {
      final previous = readyState.showDebugUsers;
      state = readyState.copyWith(showDebugUsers: value);
      if (previous != value) {
        performQuery();
      }
    }
  }

  bool _areLocationsDistant(Location a, Location b) {
    // Reduced radius for improved experience when searching
    final panRatio = greatCircleDistance(a.latLong, b.latLong) / a.radius;
    final zoomRatio = b.radius / a.radius;
    final panned = panRatio > 0.5;
    final zoomed = zoomRatio > 2.0 || zoomRatio < 0.5;
    if (panned || zoomed) {
      return true;
    }
    return false;
  }

  DiscoverReadyState? _readyState() {
    return state.map(
      init: (_) => null,
      ready: (ready) => ready,
    );
  }
}

@freezed
class DiscoverState with _$DiscoverState {
  const factory DiscoverState.init() = _Init;
  const factory DiscoverState.ready({
    required bool loading,
    required bool showDebugUsers,
    required Gender? gender,
    required List<Event> events,
    required Event? selectedEvent,
  }) = DiscoverReadyState;
}
