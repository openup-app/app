import 'dart:async';

import 'package:flutter/foundation.dart';

class StateMachineState<V> {
  const StateMachineState();

  Future<V> onEnter() => Future.value();

  Future<void> onExit() => Future.value();
}

abstract class StateMachine<V, T extends StateMachineState<V>> {
  @protected
  bool _disposed = false;

  @protected
  late T machineState;

  @protected
  void initialState(T state) => this.machineState = state;

  @protected
  Future<V> transitionTo(T newState) async {
    if (_disposed) {
      return Future.value();
    }

    await machineState.onExit();
    machineState = newState;
    return newState.onEnter();
  }

  Future<void> dispose() {
    _disposed = true;
    return machineState.onExit();
  }
}
