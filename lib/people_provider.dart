import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_provider.dart';

part 'people_provider.freezed.dart';

final peopleGenderFilterProvider = StateProvider<Gender?>((ref) => null);

final peopleDebugUsersFilterProvider = StateProvider<bool>((ref) => false);

final _peopleProvider = FutureProvider<IList<Profile>?>(
  (ref) async {
    final status = ref.watch(locationProvider.select((s) => s.status));
    final latLong = status?.map(
      value: (value) => value.latLong,
      denied: (_) => null,
      failure: (_) => null,
    );
    if (latLong == null) {
      return null;
    }
    final gender = ref.watch(peopleGenderFilterProvider);
    final debugUsers = ref.watch(peopleDebugUsersFilterProvider);
    final api = ref.watch(apiProvider);
    final results = await api.getDiscover(
      location: Location(
        latLong: latLong,
        radius: 24000,
      ),
      gender: gender,
      debug: debugUsers,
    );
    return results.fold(
      (l) => throw l,
      (r) => r.profiles.toIList(),
    );
  },
  dependencies: [
    locationProvider,
    peopleGenderFilterProvider,
    peopleDebugUsersFilterProvider,
    apiProvider
  ],
);

final peopleProvider = StateProvider<PeopleState>(
  (ref) {
    final latLong = ref.watch(locationProvider.select((s) => s.current));
    final result = ref.watch(_peopleProvider);
    return result.map(
      loading: (loading) => const _PeopleInitializing(),
      error: (error) => const PeopleFailed(),
      data: (data) {
        final value = data.value;
        if (value == null) {
          return const _PeopleInitializing();
        }
        return PeopleReady(
          profiles: value.toList(),
          latLong: latLong,
        );
      },
    );
  },
  dependencies: [locationProvider, _peopleProvider],
);

@freezed
class PeopleState with _$PeopleState {
  const factory PeopleState.uninitialized() = _PeopleUninitialized;
  const factory PeopleState.initializing() = _PeopleInitializing;
  const factory PeopleState.failed() = PeopleFailed;
  const factory PeopleState.ready({
    required List<Profile> profiles,
    required LatLong latLong,
  }) = PeopleReady;
}
