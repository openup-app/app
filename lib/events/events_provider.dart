import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';

part 'events_provider.freezed.dart';

final eventsProvider =
    StateNotifierProvider<EventsNotifier, EventsState>((ref) {
  final api = ref.read(apiProvider);
  return EventsNotifier(api);
});

class EventsNotifier extends StateNotifier<EventsState> {
  final Api _api;
  EventsNotifier(Api api)
      : _api = api,
        super(const EventsState(events: []));

  Future<void> refreshEvents(Location location) async {
    final result = await _api.getEvents(location);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {},
      (r) => state = state.copyWith(events: r),
    );
  }
}

final _debugEvents = [
  Event(
    id: '1',
    title: 'Sunday Brunch',
    host: const HostDetails(
      uid: 'uid',
      name: 'Tarlok',
      photo: 'https://picsum.photos/id/56/2880/1920',
    ),
    location: const EventLocation(
      latLong: LatLong(latitude: 0, longitude: 0),
      name: 'The Omlet',
    ),
    startDate: DateTime.now()
        .add(const Duration(days: 4, hours: 4, minutes: 43, seconds: 27)),
    endDate: DateTime.now()
        .add(const Duration(days: 4, hours: 6, minutes: 16, seconds: 21)),
    photo: Uri.parse('https://picsum.photos/id/16/2500/1667'),
    price: 0,
    views: 25,
    attendance: const EventAttendance.limited(3),
    description:
        'Looking to meet some locals here and get some brunch! Anyone is welcome, keeping it small only 3 spots available so click attend!',
  ),
  Event(
    id: '2',
    title: 'Dancing',
    host: const HostDetails(
      uid: 'uid',
      name: 'Cindy',
      photo: 'https://picsum.photos/id/56/2880/1920',
    ),
    location: const EventLocation(
      latLong: LatLong(latitude: 0, longitude: 0),
      name: 'Dance Hall',
    ),
    startDate: DateTime.now()
        .add(const Duration(days: 6, hours: 1, minutes: 12, seconds: 45)),
    endDate: DateTime.now()
        .add(const Duration(days: 6, hours: 4, minutes: 12, seconds: 18)),
    photo: Uri.parse('https://picsum.photos/id/21/3008/2008'),
    price: 0,
    views: 64,
    attendance: const EventAttendance.unlimited(),
    description:
        'Looking to meet some locals here and get some brunch! Anyone is welcome, keeping it small only 3 spots available so click attend!',
  ),
];

@freezed
class EventsState with _$EventsState {
  const factory EventsState({
    required List<Event> events,
  }) = _EventsState;
}
