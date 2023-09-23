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

part 'discover_provider.freezed.dart';

final eventAlertProvider = StateProvider<String?>((ref) => null);

final eventMapProvider = StateNotifierProvider<EventMapNotifier, EventMapState>(
  (ref) {
    final alertNotifier = ref.read(eventAlertProvider.notifier);
    return EventMapNotifier(
      api: ref.read(apiProvider),
      initialLocation: Location(
        latLong: ref.read(locationProvider).current,
        radius: 1500,
      ),
      onAlert: (alert) => alertNotifier.state = alert,
    );
  },
  dependencies: [apiProvider, locationProvider],
);

class EventMapNotifier extends StateNotifier<EventMapState> {
  final Api _api;
  final void Function(String alert) _onAlert;

  Location _fetchLocation;
  Location _prevFetchLocation;
  CancelableOperation<Either<ApiError, List<Event>>>? _fetchOp;
  Event? _targetEvent;

  EventMapNotifier({
    required Api api,
    required Location initialLocation,
    required void Function(String alert) onAlert,
  })  : _api = api,
        _fetchLocation = initialLocation,
        _onAlert = onAlert,
        _prevFetchLocation = initialLocation,
        super(
          EventMapState(
            initialLocation: initialLocation,
            refreshing: true,
            events: [],
            selectedEvent: null,
          ),
        ) {
    _init();
  }

  void _init() async {
    _fetchEvents();
  }

  void mapMoved(Location location) {
    if (_areLocationsDistant(location, _prevFetchLocation)) {
      _fetchLocation = location;
      _fetchEvents();
    }
  }

  set selectedEvent(Event? event) =>
      state = state.copyWith(selectedEvent: event);

  void showEvent(Event event) {
    _targetEvent = event;
    _fetchLocation = Location(
      latLong: event.location.latLong,
      radius: 1500,
    );
    _fetchEvents();
  }

  void fetchEvents() => _fetchEvents();

  void _fetchEvents() async {
    final fetchLatLong =
        _targetEvent?.location.latLong ?? _fetchLocation.latLong;
    final fetchLocation = Location(
      latLong: fetchLatLong,
      radius: _targetEvent != null ? 1500 : _fetchLocation.radius,
    );
    _prevFetchLocation = fetchLocation;
    state = state.copyWith(refreshing: true);

    _fetchOp?.cancel();
    final future = _api.getEvents(fetchLocation);
    final fetchOp = CancelableOperation.fromFuture(future);
    _fetchOp = fetchOp;
    final result = await fetchOp.value;
    if (!mounted) {
      return;
    }

    result.fold(
      _alertQueryError,
      (r) {
        final newSelectedEvent = r.firstWhereOrNull((e) {
          return (_targetEvent != null && e.id == _targetEvent?.id) ||
              (_targetEvent == null && e.id == state.selectedEvent?.id);
        });
        state = state.copyWith(
          refreshing: false,
          events: r,
          selectedEvent: newSelectedEvent,
        );
      },
    );
  }

  void _alertQueryError(ApiError error) {
    var message = errorToMessage(error);
    message = error.when(
      network: (_) => message,
      client: (client) => client.when(
        badRequest: () => 'Unable to request events',
        unauthorized: () => message,
        notFound: () => 'Something went wrong',
        forbidden: () => message,
        conflict: () => message,
      ),
      server: (_) => message,
    );
    _onAlert(message);
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
}

@freezed
class EventMapState with _$EventMapState {
  const factory EventMapState({
    required Location initialLocation,
    required bool refreshing,
    required List<Event> events,
    required Event? selectedEvent,
  }) = EventMapReadyState;
}
