import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:openup/dynamic_config/dynamic_config.dart';
import 'package:rxdart/subjects.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service side configuration provided by Firebase Remote Config.
class DynamicConfigService {
  static const _kContactInviteMessage = 'contactInviteMessage';
  static const _kLoginRequired = 'loginRequired';

  final _epoch = DateTime(1970, 01, 01);

  final DynamicConfig _defaults;
  DynamicConfig _config;
  final _remoteConfig = FirebaseRemoteConfig.instance;
  final _notificationController = BehaviorSubject<void>();
  StreamSubscription? _changeSubscription;
  bool _disposed = false;

  DynamicConfigService({
    required DynamicConfig defaults,
  })  : _defaults = defaults,
        _config = defaults;

  DynamicConfig get defaults => _defaults;

  DynamicConfig get config => _config;

  bool get loaded => _remoteConfig.lastFetchTime != _epoch;

  Future<void> init() async {
    try {
      await _remoteConfig.ensureInitialized();
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );
      _remoteConfig.setDefaults({
        _kContactInviteMessage: _defaults.contactInviteMessage,
        _kLoginRequired: _defaults.loginRequired,
      });
      await _remoteConfig.activate();
      if (!_disposed) {
        if (loaded) {
          _applyRemoteConfig();
          _notifyListeners();
        }

        await _remoteConfig.fetchAndActivate();
        if (!_disposed) {
          _applyRemoteConfig();
          _notifyListeners();

          _changeSubscription = _remoteConfig.onConfigUpdated.listen((changes) {
            _applyRemoteConfig();
            _notifyListeners();
          });
        }
      }
    } on FirebaseException catch (e, s) {
      switch (e.code) {
        case 'forbidden':
          Sentry.captureException(e, stackTrace: s);
          break;
        default:
          Sentry.captureException(e, stackTrace: s);
      }
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
    }
  }

  void onDispose() {
    _disposed = true;
    _notificationController.close();
    _changeSubscription?.cancel();
  }

  void _applyRemoteConfig() {
    _config = _config.copyWith(
      contactInviteMessage: _remoteConfig.getString(_kContactInviteMessage),
      loginRequired: _remoteConfig.getBool(_kLoginRequired),
    );
  }

  void _notifyListeners() {
    if (!_notificationController.isClosed) {
      _notificationController.add(null);
    }
  }

  Stream<void> get onChangeStream => _notificationController.stream;

  DateTime? get lastFetched => null;
}
