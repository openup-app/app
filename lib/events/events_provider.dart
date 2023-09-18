import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';

part 'events_provider.freezed.dart';

final eventsProvider = StateNotifierProvider<EventsNotifier, EventsState>(
    (ref) => EventsNotifier());

class EventsNotifier extends StateNotifier<EventsState> {
  EventsNotifier() : super(const EventsState(events: [])) {
    refreshEvents();
  }

  Future<void> refreshEvents() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      state = state.copyWith(events: List.of(_debugEvents));
    }
  }

  Future<Event?> createEvent(Event event) async {
    // TODO: Use Api get event
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return null;
    }

    final result = event.copyWith(id: Random().nextInt(123123123).toString());
    final newEvents = List.of(state.events)..add(result);
    state = state.copyWith(events: newEvents);

    return result;
  }

  Future<void> updateEvent(String id, Event event) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }

    final index = state.events.indexWhere((e) => e.id == id);
    if (index == -1) {
      return;
    }

    final newEvents = List.of(state.events)
      ..replaceRange(index, index + 1, [event]);
    state = state.copyWith(events: newEvents);
  }

  Future<void> deleteEvent(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }

    final newEvents = List.of(state.events)..removeWhere((e) => e.id == id);
    state = state.copyWith(events: newEvents);
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
