import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationRequestBuilder extends ConsumerStatefulWidget {
  final VoidCallback? onGranted;
  final void Function(NotificationToken)? onToken;
  final Widget Function(
    BuildContext context,
    bool granted,
    VoidCallback onRequest,
  ) builder;

  const NotificationRequestBuilder({
    super.key,
    this.onGranted,
    this.onToken,
    required this.builder,
  });

  @override
  ConsumerState<NotificationRequestBuilder> createState() =>
      _NotificationRequestBuilderState();
}

class _NotificationRequestBuilderState
    extends ConsumerState<NotificationRequestBuilder> {
  late final StreamSubscription _tokenSubscription;
  final _permissionController = StreamController<bool>.broadcast();

  @override
  void initState() {
    super.initState();
    final notificationManager = ref.read(notificationManagerProvider);
    notificationManager.hasNotificationPermission().then((value) {
      if (mounted) {
        _permissionController.add(value);
      }
    });

    if (widget.onToken != null) {
      _tokenSubscription = notificationManager.tokenStream.listen((token) {
        widget.onToken?.call(token);
      });
    }
  }

  @override
  void dispose() {
    _tokenSubscription.cancel();
    _permissionController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycle(
      onResumed: () async {
        final notificationManager = ref.read(notificationManagerProvider);
        final granted = await notificationManager.hasNotificationPermission();
        if (mounted) {
          _permissionController.add(granted);
        }
      },
      child: StreamBuilder<bool>(
        stream: _permissionController.stream,
        initialData: false,
        builder: (context, snapshot) {
          final granted = snapshot.requireData;
          return widget.builder(context, granted, _requestPermissions);
        },
      ),
    );
  }

  void _requestPermissions() async {
    final notificationManager = ref.read(notificationManagerProvider);
    final permanentlyDenied = await notificationManager.isPermanentlyDenied();
    if (!mounted) {
      return;
    }
    if (permanentlyDenied) {
      _permissionController.add(false);
      openAppSettings();
    } else {
      final notificationManager = ref.read(notificationManagerProvider);
      final granted = await notificationManager.requestNotificationPermission();
      if (mounted) {
        _permissionController.add(granted);
        if (granted) {
          widget.onGranted?.call();
        }
      }
    }
  }
}
