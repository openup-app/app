import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';

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

final eventParicipantsProvider =
    FutureProvider.family<IList<SimpleProfile>, String>(
        (ref, String eventId) async {
  final api = ref.watch(apiProvider);
  final result = await api.getParticipantSimpleProfiles(eventId);
  return result.fold(
    (l) => throw l,
    (r) => r.toIList(),
  );
});

final hostingEventsProvider = Provider<IList<String>>((ref) {
  final uid = ref.watch(uidProvider);
  return ref.watch(eventStoreProvider.select((s) =>
      s.values.where((e) => e.host.uid == uid).map((e) => e.id).toIList()));
});

final attendingEventsProvider = Provider<IList<String>>((ref) {
  final uid = ref.watch(uidProvider);
  return ref.watch(eventStoreProvider.select((s) => s.values
      .where((e) => e.participants.uids.contains(uid))
      .map((e) => e.id)
      .toIList()));
});

final nearbyEventsProvider =
    StateNotifierProvider<NearbyEventsNotifier, NearbyEventsState>((ref) {
  return NearbyEventsNotifier(
    api: ref.read(apiProvider),
    eventCacheNotifier: ref.read(eventStoreProvider.notifier),
  );
});

class NearbyEventsNotifier extends StateNotifier<NearbyEventsState> {
  final Api _api;
  final StateNotifier<IMap<String, Event>> _eventCacheNotifier;
  NearbyEventsNotifier({
    required Api api,
    required StateNotifier<IMap<String, Event>> eventCacheNotifier,
  })  : _api = api,
        _eventCacheNotifier = eventCacheNotifier,
        super(const NearbyEventsState(eventIds: IListConst([])));

  Future<void> refresh(Location location) async {
    final result = await _api.getEvents(location);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {},
      (r) {
        _eventCacheNotifier.state = _eventCacheNotifier.state
            .addEntries(r.map((e) => MapEntry(e.id, e)));
        return state = state.copyWith(
          eventIds: r.map((e) => e.id).toIList(),
        );
      },
    );
  }
}

@freezed
class NearbyEventsState with _$NearbyEventsState {
  const factory NearbyEventsState({
    required IList<String> eventIds,
  }) = _NearbyEventsState;
}
