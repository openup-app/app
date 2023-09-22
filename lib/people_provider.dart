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

part 'people_provider.freezed.dart';

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

  CancelableOperation<Either<ApiError, DiscoverResultsPage>>?
      _discoverOperation;
  Location? _mapLocation;
  Location? _prevQueryLocation;
  String? _selectUidWhenAvailable;

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
      state = readyState.copyWith(selectedProfile: null);
      return _queryProfilesAt(location.copyWith(radius: location.radius * 0.5));
    }
    return Future.value();
  }

  Future<void> _queryProfilesAt(Location location) async {
    var readyState = _readyState();
    if (readyState == null) {
      return Future.value();
    }
    state = readyState.copyWith(loading: true);
    _discoverOperation?.cancel();
    final discoverFuture = api.getDiscover(
      location: location,
      gender: readyState.gender,
      debug: readyState.showDebugUsers,
    );
    _discoverOperation = CancelableOperation.fromFuture(discoverFuture);
    final profiles = await _discoverOperation?.value;

    readyState = _readyState();
    if (!mounted || readyState == null) {
      return;
    }

    readyState = readyState.copyWith(loading: false);
    state = readyState;
    if (profiles == null) {
      return;
    }

    profiles.fold(
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
        DiscoverProfile? profileToSelect;
        final targetUid = _selectUidWhenAvailable;
        if (targetUid != null) {
          profileToSelect =
              r.profiles.firstWhereOrNull((p) => p.profile.uid == targetUid);
        }
        _selectUidWhenAvailable = null;
        state = readyState!.copyWith(
          selectedProfile: profileToSelect,
          profiles: r.profiles,
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
        profiles: [],
        selectedProfile: null,
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
        profiles: [],
        selectedProfile: null,
      );
    }
  }

  void selectProfile(DiscoverProfile? profile) {
    final readyState = _readyState();
    if (readyState != null) {
      state = readyState.copyWith(
        loading: false,
        selectedProfile: profile,
      );
      _discoverOperation?.cancel();
    }
  }

  void setFavorite(String uid, bool favorite) async {
    var readyState = _readyState();
    if (readyState == null) {
      return;
    }

    Either<ApiError, DiscoverProfile> result;
    var index = readyState.profiles.indexWhere((p) => p.profile.uid == uid);

    if (index != -1) {
      final profile = readyState.profiles[index];
      final newProfiles = List.of(readyState.profiles);
      newProfiles.replaceRange(
        index,
        index + 1,
        [profile.copyWith(favorite: favorite)],
      );
      state = readyState.copyWith(
        profiles: newProfiles,
      );
    }

    readyState = _readyState()!;
    final selectedProfile = readyState.selectedProfile;
    if (selectedProfile != null && selectedProfile.profile.uid == uid) {
      state = readyState.copyWith.selectedProfile!(favorite: favorite);
    }

    if (favorite) {
      result = await api.addFavorite(uid);
    } else {
      result = await api.addFavorite(uid);
    }

    if (!mounted) {
      return;
    }

    // index = _profiles.indexWhere((p) => p.profile.uid == profile.profile.uid);
    // result.fold(
    //   (l) {
    //     if (index != -1) {
    //       setState(() => _profiles.replaceRange(index, index + 1, [profile]));
    //     }
    //     displayError(context, l);
    //   },
    //   (r) {
    //     if (index != -1) {
    //       setState(() => _profiles.replaceRange(index, index + 1, [r]));
    //     }
    //   },
    // );
  }

  void userBlocked(String uid) {
    final readyState = _readyState();
    if (readyState != null) {
      final newProfiles = List.of(readyState.profiles);
      newProfiles.removeWhere((p) => p.profile.uid == uid);
      state = readyState.copyWith(
        profiles: newProfiles,
      );
      _discoverOperation?.cancel();
    }
  }

  void uidToSelectWhenAvailable(String? uid) {
    _selectUidWhenAvailable = uid;
    final targetUid = _selectUidWhenAvailable;
    final readyState = _readyState();
    if (readyState != null && targetUid != null) {
      final profile = readyState.profiles
          .firstWhereOrNull((p) => p.profile.uid == targetUid);
      if (profile != null) {
        state = readyState.copyWith(selectedProfile: profile);
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
    required List<DiscoverProfile> profiles,
    required DiscoverProfile? selectedProfile,
  }) = DiscoverReadyState;
}
