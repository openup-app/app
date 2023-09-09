import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/location/location_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void showLocationPermissionRationale(BuildContext context) {
  showCupertinoDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: const Text(
          'Location Services',
          textAlign: TextAlign.center,
        ),
        content: const Text(
            'Location needs to be on in order to discover people near you.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer(
            builder: (context, ref, child) {
              return CupertinoDialogAction(
                onPressed: () async {
                  if (await openAppSettings() && context.mounted) {
                    ref.read(locationProvider.notifier).retryInitLocation();
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Enable in Settings'),
              );
            },
          ),
        ],
      );
    },
  );
}
