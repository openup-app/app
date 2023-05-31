import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:openup/api/api.dart';
import 'package:openup/util/state_machine.dart';
import 'package:openup/widgets/discover_map.dart';

typedef RenderStartCallback = Future<List<RenderedProfile>> Function(
    List<DiscoverProfile> profiles);
typedef RenderEndCallback = void Function(List<RenderedProfile> markers);

class MarkerRenderingStateMachine extends StateMachine<void, _MarkerState> {
  final RenderStartCallback onRenderStart;
  final RenderEndCallback onRenderEnd;

  MarkerRenderingStateMachine({
    required this.onRenderStart,
    required this.onRenderEnd,
  }) {
    reset();
  }

  Future<void> profilesUpdated({required List<DiscoverProfile> profiles}) =>
      machineState.profilesUpdated(profiles: profiles);

  void reset() {
    final state = _Idle(
      stateMachine: this,
      profiles: [],
      cache: {},
    );
    initialState(state);
    machineState = state;
  }

  @protected
  Future<void> _transitionTo(_MarkerState state) => transitionTo(state);
}

abstract class _MarkerState extends StateMachineState<void> {
  final MarkerRenderingStateMachine _stateMachine;

  _MarkerState(this._stateMachine);

  @protected
  MarkerRenderingStateMachine get stateMachine => _stateMachine;

  Future<void> profilesUpdated({required List<DiscoverProfile> profiles});

  List<DiscoverProfile> _newlyAddedProfiles(
    List<DiscoverProfile> previousProfiles,
    List<DiscoverProfile> nextProfiles,
  ) {
    final addedProfiles = <DiscoverProfile>[];
    final previousUids = previousProfiles.map((p) => p.profile.uid).toSet();
    for (final profile in nextProfiles) {
      if (!previousUids.contains(profile.profile.uid)) {
        addedProfiles.add(profile);
      }
    }
    return addedProfiles;
  }
}

class _Idle extends _MarkerState {
  final List<DiscoverProfile> _profiles;
  final Map<String, RenderedProfile> _cache;

  _Idle({
    required MarkerRenderingStateMachine stateMachine,
    required List<DiscoverProfile> profiles,
    required Map<String, RenderedProfile> cache,
  })  : _profiles = List.of(profiles),
        _cache = Map.of(cache),
        super(stateMachine);

  @override
  Future<void> profilesUpdated({required List<DiscoverProfile> profiles}) {
    final newProfiles = _newlyAddedProfiles(_profiles, profiles);
    _profiles
      ..clear()
      ..addAll(profiles);
    if (newProfiles.isEmpty) {
      return Future.value();
    }
    return stateMachine._transitionTo(
      _RenderingMarkers(
        stateMachine: _stateMachine,
        unrenderedProfiles: newProfiles,
        profiles: profiles,
        cache: _cache,
      ),
    );
  }
}

class _RenderingMarkers extends _MarkerState {
  final List<DiscoverProfile> _unrenderedProfiles;
  final List<DiscoverProfile> _profiles;
  final Map<String, RenderedProfile> _cache;

  late final CancelableOperation<List<RenderedProfile>> _renderingOperation;

  _RenderingMarkers({
    required MarkerRenderingStateMachine stateMachine,
    required List<DiscoverProfile> unrenderedProfiles,
    required List<DiscoverProfile> profiles,
    required Map<String, RenderedProfile> cache,
  })  : _unrenderedProfiles = unrenderedProfiles,
        _profiles = List.of(profiles),
        _cache = Map.of(cache),
        super(stateMachine);

  @override
  Future<void> onEnter() async {
    final cachedUids = _cache.keys.toList();
    final uncachedProfiles = _unrenderedProfiles
        .where((p) => !cachedUids.contains(p.profile.uid))
        .toList();
    _renderingOperation = CancelableOperation.fromFuture(
        _stateMachine.onRenderStart(uncachedProfiles));
    final markers = await _renderingOperation.value;
    _cache.addEntries(markers.map((r) => MapEntry(r.profile.profile.uid, r)));
    final output = <RenderedProfile>[];
    for (final profile in _unrenderedProfiles) {
      output.add(_cache[profile.profile.uid]!);
    }
    _stateMachine.onRenderEnd(output);
    return _stateMachine._transitionTo(
      _Idle(
        stateMachine: _stateMachine,
        profiles: _profiles,
        cache: _cache,
      ),
    );
  }

  @override
  Future<void> onExit() {
    if (!_renderingOperation.isCompleted) {
      _renderingOperation.cancel();
    }
    return Future.value();
  }

  @override
  Future<void> profilesUpdated({required List<DiscoverProfile> profiles}) {
    final newProfiles = _newlyAddedProfiles(_profiles, profiles);
    _profiles
      ..clear()
      ..addAll(profiles);
    if (newProfiles.isEmpty) {
      return Future.value();
    }
    return _stateMachine._transitionTo(
      _RenderingMarkers(
        stateMachine: _stateMachine,
        unrenderedProfiles: newProfiles,
        profiles: profiles,
        cache: _cache,
      ),
    );
  }
}
