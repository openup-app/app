import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_provider.dart';

part 'people_provider.freezed.dart';

final peopleGenderFilterProvider = StateProvider<Gender?>((ref) => null);

final peopleDebugUsersFilterProvider = StateProvider<bool>((ref) => false);

final _peopleProvider = FutureProvider<IList<DiscoverProfile>>((ref) async {
  final latLong = ref.read(locationProvider2.select((s) => s.current));
  final gender = ref.watch(peopleGenderFilterProvider);
  final debugUsers = ref.watch(peopleDebugUsersFilterProvider);
  final api = ref.watch(apiProvider);
  final results = await api.getDiscover(
    location: Location(
      latLong: latLong,
      radius: 16000,
    ),
    gender: gender,
    debug: debugUsers,
  );
  return results.fold(
    (l) => throw l,
    (r) => r.profiles.toIList(),
  );
});

final peopleProvider = StateProvider<PeopleState>((ref) {
  final latLong = ref.read(locationProvider2.select((s) => s.current));
  final result = ref.watch(_peopleProvider);
  return result.map(
    loading: (loading) => const _PeopleInitializing(),
    error: (error) => const _PeopleFailed(),
    data: (data) => _PeopleReady(
      profiles: data.value.toList(),
      latLong: latLong,
    ),
  );
});

@freezed
class PeopleState with _$PeopleState {
  const factory PeopleState.uninitialized() = _PeopleUninitialized;
  const factory PeopleState.initializing() = _PeopleInitializing;
  const factory PeopleState.failed() = _PeopleFailed;
  const factory PeopleState.ready({
    required List<DiscoverProfile> profiles,
    required LatLong latLong,
  }) = _PeopleReady;
}
