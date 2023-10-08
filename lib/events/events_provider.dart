import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_map_view.dart';
import 'package:openup/location/location_provider.dart';

part 'events_provider.freezed.dart';

final eventStoreProvider = StateProvider<IMap<String, Event>>((ref) => IMap());

final eventProvider =
    StateProvider.family<Event, String>((ref, String eventId) {
  return ref.watch(eventStoreProvider.select((s) {
    try {
      return s[eventId]!;
    } catch (e) {
      final ids = s.keys.toList();
      throw 'Event Store does not contain $eventId (Store contains $ids). Store the event before letting the UI watch the event';
    }
  }));
});

final eventParticipantsProvider =
    FutureProvider.family<IList<SimpleProfile>, String>(
        (ref, String eventId) async {
  final api = ref.watch(apiProvider);
  final result = await api.getParticipantSimpleProfiles(eventId);
  return result.fold(
    (l) => throw l,
    (r) => r.toIList(),
  );
});

final nearbyEventsDateFilterProvider =
    StateNotifierProvider<NearbyEventDateFilterNotifier, DateTime?>((ref) {
  return NearbyEventDateFilterNotifier(ref);
});

class NearbyEventDateFilterNotifier extends StateNotifier<DateTime?> {
  final Ref _ref;

  NearbyEventDateFilterNotifier(this._ref) : super(null);

  set date(DateTime? value) {
    state = value;
    _ref.invalidate(_nearbyEventsProviderInternal);
  }
}

final _nearbyEventsProviderInternal = FutureProvider<IList<Event>>(
  (ref) async {
    final api = ref.watch(apiProvider);
    final latLong = ref.watch(locationProvider.select((s) => s.current));
    final dateFilter = ref.watch(nearbyEventsDateFilterProvider);
    final result = await api.getEvents(
      Location(latLong: latLong, radius: 16000),
      date: dateFilter,
    );
    return result.fold(
      (l) => throw l,
      (r) => r.toIList(),
    );
  },
  dependencies: [apiProvider, locationProvider, nearbyEventsDateFilterProvider],
);

final nearbyEventsProvider = StateProvider<NearbyEventsState>(
  (ref) {
    final eventStoreNotifier = ref.watch(eventStoreProvider.notifier);
    ref.listen(
      _nearbyEventsProviderInternal,
      (previous, next) {
        next.when(
          loading: () {},
          error: (_, __) {},
          data: (events) {
            return eventStoreNotifier.state = eventStoreNotifier.state
                .addEntries(events.map((e) => MapEntry(e.id, e)));
          },
        );
      },
    );

    final events = ref.watch(_nearbyEventsProviderInternal);
    final storedEventIds =
        ref.watch(eventStoreProvider.select((s) => s.keys.toList()));
    if (events.isRefreshing) {
      return const NearbyEventsState.loading();
    }
    return events.when(
      loading: () => const NearbyEventsState.loading(),
      error: (_, __) => const NearbyEventsState.error(),
      data: (events) {
        final sortedEvents = List.of(events)..sort(dateAscendingEventSorter);
        return NearbyEventsState.data(sortedEvents
            .where((e) => storedEventIds.contains(e.id))
            .map((e) => e.id)
            .toList());
      },
    );
  },
  dependencies: [eventStoreProvider, _nearbyEventsProviderInternal],
);

@freezed
class NearbyEventsState with _$NearbyEventsState {
  const factory NearbyEventsState.loading() = _NearbyEventsLoading;
  const factory NearbyEventsState.error() = _NearbyEventsError;
  const factory NearbyEventsState.data(List<String> eventIds) =
      _NearbyEventsData;
}

final _hostingEventsProviderInternal = FutureProvider<IList<Event>>(
  (ref) async {
    final api = ref.watch(apiProvider);
    final uid = ref.watch(uidProvider);
    final result = await api.getMyHostedEvents(uid);
    return result.fold(
      (l) => throw l,
      (r) => r.toIList(),
    );
  },
  dependencies: [apiProvider, uidProvider],
);

final hostingEventsProvider = Provider<HostingEventsState>(
  (ref) {
    final eventStoreNotifier = ref.watch(eventStoreProvider.notifier);
    ref.listen(
      _hostingEventsProviderInternal,
      (previous, next) {
        if (next.hasValue) {
          final events = next.asData!.value;
          eventStoreNotifier.state = eventStoreNotifier.state
              .addEntries(events.map((e) => MapEntry(e.id, e)));
        }
      },
    );

    final events = ref.watch(_hostingEventsProviderInternal);
    final storedEventIds =
        ref.watch(eventStoreProvider.select((s) => s.keys.toList()));
    if (events.isRefreshing) {
      return const HostingEventsState.loading();
    }
    return events.when(
      loading: () => const HostingEventsState.loading(),
      error: (_, __) => const HostingEventsState.error(),
      data: (events) {
        final sortedEvents = List.of(events)..sort(dateAscendingEventSorter);
        return HostingEventsState.data(sortedEvents
            .where((e) => storedEventIds.contains(e.id))
            .map((e) => e.id)
            .toList());
      },
    );
  },
  dependencies: [eventStoreProvider, _hostingEventsProviderInternal],
);

@freezed
class HostingEventsState with _$HostingEventsState {
  const factory HostingEventsState.loading() = _HostingEventsLoading;
  const factory HostingEventsState.error() = _HostingEventsError;
  const factory HostingEventsState.data(List<String> eventIds) =
      _HostingEventsData;
}

final _attendingEventsProviderInternal = FutureProvider<IList<Event>>(
  (ref) async {
    final api = ref.watch(apiProvider);
    final result = await api.getMyAttendingEvents();
    return result.fold(
      (l) => throw l,
      (r) => r.toIList(),
    );
  },
  dependencies: [apiProvider],
);

final attendingEventsProvider = Provider<AttendingEventsState>(
  (ref) {
    final eventStoreNotifier = ref.watch(eventStoreProvider.notifier);
    ref.listen(
      _attendingEventsProviderInternal,
      (previous, next) {
        if (next.hasValue) {
          final events = next.asData!.value;
          eventStoreNotifier.state = eventStoreNotifier.state
              .addEntries(events.map((e) => MapEntry(e.id, e)));
        }
      },
    );

    final events = ref.watch(_attendingEventsProviderInternal);
    final storedEventIds =
        ref.watch(eventStoreProvider.select((s) => s.keys.toList()));
    if (events.isRefreshing) {
      return const AttendingEventsState.loading();
    }
    return events.when(
      loading: () => const AttendingEventsState.loading(),
      error: (_, __) => const AttendingEventsState.error(),
      data: (events) {
        final sortedEvents = List.of(events)..sort(dateAscendingEventSorter);
        return AttendingEventsState.data(sortedEvents
            .where((e) => storedEventIds.contains(e.id))
            .map((e) => e.id)
            .toList());
      },
    );
  },
  dependencies: [eventStoreProvider, _attendingEventsProviderInternal],
);

@freezed
class AttendingEventsState with _$AttendingEventsState {
  const factory AttendingEventsState.loading() = _AttendingEventsLoading;
  const factory AttendingEventsState.error() = _AttendingEventsError;
  const factory AttendingEventsState.data(List<String> eventIds) =
      _AttendingEventsData;
}

final eventManagementProvider =
    StateNotifierProvider<EventManagementNotifier, void>(
  (ref) {
    return EventManagementNotifier(
      api: ref.watch(apiProvider),
      eventStoreNotifier: ref.watch(eventStoreProvider.notifier),
      onRefreshNearbyEvents: () {
        ref.invalidate(_nearbyEventsProviderInternal);
        ref.invalidate(mapEventsStateProviderInternal);
      },
      onRefreshHostingEvents: () =>
          ref.invalidate(_hostingEventsProviderInternal),
      onRefreshAttendingEvents: () =>
          ref.invalidate(_attendingEventsProviderInternal),
      onRefreshEvent: (eventId) {
        ref.invalidate(_hostingEventsProviderInternal);
        ref.invalidate(_attendingEventsProviderInternal);
        ref.invalidate(eventParticipantsProvider(eventId));
      },
    );
  },
  dependencies: [
    apiProvider,
    eventStoreProvider,
    _nearbyEventsProviderInternal,
    _hostingEventsProviderInternal,
    _attendingEventsProviderInternal,
    eventParticipantsProvider
  ],
);

class EventManagementNotifier extends StateNotifier<void> {
  final Api _api;
  final StateNotifier<IMap<String, Event>> _eventStoreNotifier;
  final void Function() _onRefreshNearbyEvents;
  final void Function() _onRefreshHostingEvents;
  final void Function() _onRefreshAttendingEvents;
  final void Function(String eventId) _onRefreshEvent;

  EventManagementNotifier({
    required Api api,
    required StateNotifier<IMap<String, Event>> eventStoreNotifier,
    required void Function() onRefreshNearbyEvents,
    required void Function() onRefreshHostingEvents,
    required void Function() onRefreshAttendingEvents,
    required void Function(String eventId) onRefreshEvent,
  })  : _api = api,
        _eventStoreNotifier = eventStoreNotifier,
        _onRefreshNearbyEvents = onRefreshNearbyEvents,
        _onRefreshHostingEvents = onRefreshHostingEvents,
        _onRefreshAttendingEvents = onRefreshAttendingEvents,
        _onRefreshEvent = onRefreshEvent,
        super(null);

  Future<bool> createEvent(EventSubmission submission) async {
    final result = await _api.createEvent(submission);
    if (!mounted) {
      return false;
    }

    return result.fold(
      (l) => false,
      (r) {
        _eventStoreNotifier.state = _eventStoreNotifier.state.add(r.id, r);
        _onRefreshNearbyEvents();
        _onRefreshHostingEvents();
        _onRefreshAttendingEvents();
        return true;
      },
    );
  }

  Future<bool> updateEvent(String eventId, EventSubmission submission) async {
    final result = await _api.updateEvent(eventId, submission);
    if (!mounted) {
      return false;
    }

    return result.fold(
      (l) => false,
      (r) {
        _eventStoreNotifier.state = _eventStoreNotifier.state.add(r.id, r);
        _onRefreshEvent(eventId);
        return true;
      },
    );
  }

  Future<bool> deleteEvent(String eventId) async {
    final result = await _api.deleteEvent(eventId);
    if (!mounted) {
      return false;
    }

    return result.fold(
      (l) => false,
      (r) {
        _eventStoreNotifier.state = _eventStoreNotifier.state.remove(eventId);
        _onRefreshNearbyEvents();
        _onRefreshHostingEvents();
        _onRefreshAttendingEvents();
        return true;
      },
    );
  }

  Future<void> updateEventParticipation(
      String eventId, bool participating) async {
    final result = await _api.updateEventParticipation(eventId, participating);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {},
      (r) {
        _eventStoreNotifier.state =
            _eventStoreNotifier.state.update(eventId, (_) => r);
        _onRefreshEvent(eventId);
      },
    );
  }
}

int dateAscendingEventSorter(Event a, Event b) =>
    a.startDate.compareTo(b.startDate);
