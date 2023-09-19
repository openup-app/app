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

@freezed
class EventsState with _$EventsState {
  const factory EventsState({
    required List<Event> events,
  }) = _EventsState;
}
