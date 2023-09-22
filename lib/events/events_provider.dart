import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
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

final _nearbyEventsProviderInternal = FutureProvider<IList<Event>>((ref) async {
  final api = ref.watch(apiProvider);
  final latLong = ref.watch(locationProvider.select((s) => s.current));
  final result = await api.getEvents(Location(latLong: latLong, radius: 2000));
  return result.fold(
    (l) => throw l,
    (r) => r.toIList(),
  );
});

final nearbyEventsProvider = StateProvider<NearbyEventsState>((ref) {
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
  return events.when(
    loading: () => const NearbyEventsState.loading(),
    error: (_, __) => const NearbyEventsState.error(),
    data: (events) => NearbyEventsState.data(events
        .where((e) => storedEventIds.contains(e.id))
        .map((e) => e.id)
        .toList()),
  );
});

@freezed
class NearbyEventsState with _$NearbyEventsState {
  const factory NearbyEventsState.loading() = _NearbyEventsLoading;
  const factory NearbyEventsState.error() = _NearbyEventsError;
  const factory NearbyEventsState.data(List<String> eventIds) =
      _NearbyEventsData;
}

final _hostingEventsProviderInternal =
    FutureProvider<IList<Event>>((ref) async {
  final api = ref.watch(apiProvider);
  final uid = ref.watch(uidProvider);
  final result = await api.getMyHostedEvents(uid);
  return result.fold(
    (l) => throw l,
    (r) => r.toIList(),
  );
});

final hostingEventsProvider = Provider<HostingEventsState>((ref) {
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
  return events.when(
    loading: () => const HostingEventsState.loading(),
    error: (_, __) => const HostingEventsState.error(),
    data: (events) => HostingEventsState.data(events
        .where((e) => storedEventIds.contains(e.id))
        .map((e) => e.id)
        .toList()),
  );
});

@freezed
class HostingEventsState with _$HostingEventsState {
  const factory HostingEventsState.loading() = _HostingEventsLoading;
  const factory HostingEventsState.error() = _HostingEventsError;
  const factory HostingEventsState.data(List<String> eventIds) =
      _HostingEventsData;
}

final _attendingEventsProvider = FutureProvider<IList<Event>>((ref) async {
  final api = ref.watch(apiProvider);
  final result = await api.getMyAttendingEvents();
  return result.fold(
    (l) => throw l,
    (r) => r.toIList(),
  );
});

final attendingEventsProvider = Provider<AttendingEventsState>((ref) {
  final eventStoreNotifier = ref.watch(eventStoreProvider.notifier);
  ref.listen(
    _attendingEventsProvider,
    (previous, next) {
      if (next.hasValue) {
        final events = next.asData!.value;
        eventStoreNotifier.state = eventStoreNotifier.state
            .addEntries(events.map((e) => MapEntry(e.id, e)));
      }
    },
  );

  final events = ref.watch(_attendingEventsProvider);
  final storedEventIds =
      ref.watch(eventStoreProvider.select((s) => s.keys.toList()));
  return events.when(
    loading: () => const AttendingEventsState.loading(),
    error: (_, __) => const AttendingEventsState.error(),
    data: (events) => AttendingEventsState.data(events
        .where((e) => storedEventIds.contains(e.id))
        .map((e) => e.id)
        .toList()),
  );
});

@freezed
class AttendingEventsState with _$AttendingEventsState {
  const factory AttendingEventsState.loading() = _AttendingEventsLoading;
  const factory AttendingEventsState.error() = _AttendingEventsError;
  const factory AttendingEventsState.data(List<String> eventIds) =
      _AttendingEventsData;
}

final eventManagementProvider =
    StateNotifierProvider<EventManagementNotifier, void>((ref) {
  return EventManagementNotifier(
    api: ref.watch(apiProvider),
    eventStoreNotifier: ref.watch(eventStoreProvider.notifier),
    onRefreshNearbyEvents: () => ref.invalidate(_nearbyEventsProviderInternal),
  );
});

class EventManagementNotifier extends StateNotifier<void> {
  final Api _api;
  final StateNotifier<IMap<String, Event>> _eventStoreNotifier;
  final void Function() _onRefreshNearbyEvents;

  EventManagementNotifier({
    required Api api,
    required StateNotifier<IMap<String, Event>> eventStoreNotifier,
    required void Function() onRefreshNearbyEvents,
  })  : _api = api,
        _eventStoreNotifier = eventStoreNotifier,
        _onRefreshNearbyEvents = onRefreshNearbyEvents,
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
      },
    );
  }
}
