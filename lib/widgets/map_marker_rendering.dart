import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:openup/util/state_machine.dart';
import 'package:openup/widgets/map_display.dart';

typedef RenderStartCallback = Future<List<RenderedItem>> Function(
    List<MapItem> items);
typedef RenderEndCallback = void Function(List<RenderedItem> markers);

class MarkerRenderingStateMachine extends StateMachine<void, _MarkerState> {
  final RenderStartCallback onRenderStart;
  final RenderEndCallback onRenderEnd;

  MarkerRenderingStateMachine({
    required this.onRenderStart,
    required this.onRenderEnd,
  }) {
    reset();
  }

  Future<void> itemsUpdated({required List<MapItem> items}) =>
      machineState.itemsUpdated(items: items);

  void reset() {
    final state = _Idle(
      stateMachine: this,
      items: [],
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

  Future<void> itemsUpdated({required List<MapItem> items});

  List<MapItem> _newlyAddedItems(
    List<MapItem> previousItems,
    List<MapItem> nextItems,
  ) {
    final addedItems = <MapItem>[];
    final previousIds = previousItems.map((i) => i.id).toSet();
    for (final item in nextItems) {
      if (!previousIds.contains(item.id)) {
        addedItems.add(item);
      }
    }
    return addedItems;
  }
}

class _Idle extends _MarkerState {
  final List<MapItem> _items;
  final Map<int, RenderedItem> _cache;

  _Idle({
    required MarkerRenderingStateMachine stateMachine,
    required List<MapItem> items,
    required Map<int, RenderedItem> cache,
  })  : _items = List.of(items),
        _cache = Map.of(cache),
        super(stateMachine);

  @override
  Future<void> itemsUpdated({required List<MapItem> items}) {
    final newProfiles = _newlyAddedItems(_items, items);
    _items
      ..clear()
      ..addAll(items);
    if (newProfiles.isEmpty) {
      return Future.value();
    }
    return stateMachine._transitionTo(
      _RenderingMarkers(
        stateMachine: _stateMachine,
        unrenderedItems: newProfiles,
        items: items,
        cache: _cache,
      ),
    );
  }
}

class _RenderingMarkers extends _MarkerState {
  final List<MapItem> _unrenderedItems;
  final List<MapItem> _items;
  final Map<int, RenderedItem> _cache;

  late final CancelableOperation<List<RenderedItem>> _renderingOperation;

  _RenderingMarkers({
    required MarkerRenderingStateMachine stateMachine,
    required List<MapItem> unrenderedItems,
    required List<MapItem> items,
    required Map<int, RenderedItem> cache,
  })  : _unrenderedItems = unrenderedItems,
        _items = List.of(items),
        _cache = Map.of(cache),
        super(stateMachine);

  @override
  Future<void> onEnter() async {
    final cachedUids = _cache.keys.toList();
    final uncachedItems =
        _unrenderedItems.where((i) => !cachedUids.contains(i.id)).toList();
    _renderingOperation = CancelableOperation.fromFuture(
        _stateMachine.onRenderStart(uncachedItems));
    final markers = await _renderingOperation.value;
    _cache.addEntries(markers.map((r) => MapEntry(r.item.id, r)));
    final output = <RenderedItem>[];
    for (final item in _unrenderedItems) {
      output.add(_cache[item.id]!);
    }
    _stateMachine.onRenderEnd(output);
    return _stateMachine._transitionTo(
      _Idle(
        stateMachine: _stateMachine,
        items: _items,
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
  Future<void> itemsUpdated({required List<MapItem> items}) {
    final newItems = _newlyAddedItems(_items, items);
    _items
      ..clear()
      ..addAll(items);
    if (newItems.isEmpty) {
      return Future.value();
    }
    return _stateMachine._transitionTo(
      _RenderingMarkers(
        stateMachine: _stateMachine,
        unrenderedItems: newItems,
        items: items,
        cache: _cache,
      ),
    );
  }
}
