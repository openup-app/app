import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/signup_background.dart';
import 'package:permission_handler/permission_handler.dart';

class SignupPermissionsScreen extends ConsumerStatefulWidget {
  const SignupPermissionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupPermissionsScreen> createState() =>
      _SignUpPermissionsState();
}

class _SignUpPermissionsState extends ConsumerState<SignupPermissionsScreen> {
  bool _hasLocationPermission = false;
  bool _hasContactsPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndMaybeNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    return AppLifecycle(
      onResumed: routeCurrent ? _checkPermissionsAndMaybeNavigate : null,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SignupBackground(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const SizedBox(height: 16),
              const Spacer(),
              const Text(
                'Plus One needs your location and contacts to help\nyou have the best experience.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color.fromRGBO(0x30, 0x30, 0x30, 1.0),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 51),
              PermissionButton(
                icon: const Icon(Icons.public),
                label: const Text('Enable Location'),
                granted: _hasLocationPermission,
                onPressed: () {
                  Permission.location
                      .request()
                      .then((status) =>
                          _updateLocationStatus(status, openSettings: true))
                      .whenComplete(_checkPermissionsAndMaybeNavigate);
                },
              ),
              const SizedBox(height: 27),
              PermissionButton(
                icon: const Icon(Icons.import_contacts),
                label: const Text('Enable Contacts'),
                granted: _hasContactsPermission,
                onPressed: () {
                  Permission.contacts
                      .request()
                      .then((status) =>
                          _updateContactsStatus(status, openSettings: true))
                      .whenComplete(_checkPermissionsAndMaybeNavigate);
                },
              ),
              const SizedBox(height: 50),
              Button(
                onPressed: _hasLocationPermission
                    ? _checkLocationPermissionOnlyAndMaybeNavigate
                    : null,
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'skip contacts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(0x30, 0x30, 0x30, 1.0),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Plus One cares about your privacy. We will not\ntext, call or spam anyone from your contacts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkPermissionsAndMaybeNavigate({bool openSettings = false}) async {
    final statuses = await Future.wait([
      Permission.location.status,
      Permission.contacts.status,
    ]);
    if (!mounted) {
      return;
    }

    final locationStatus = statuses[0];
    final contactsStatus = statuses[1];
    _updateLocationStatus(locationStatus, openSettings: openSettings);
    _updateContactsStatus(contactsStatus, openSettings: openSettings);

    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (_hasLocationPermission && _hasContactsPermission && routeCurrent) {
      ref.read(analyticsProvider).trackSignupGrantPermissions();
      context.pushNamed('signup_profile');
    }
  }

  void _checkLocationPermissionOnlyAndMaybeNavigate({
    bool openSettings = false,
  }) async {
    final locationStatus = await Permission.location.status;
    if (!mounted) {
      return;
    }

    _updateLocationStatus(locationStatus, openSettings: openSettings);

    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (_hasLocationPermission && routeCurrent) {
      ref.read(analyticsProvider).trackSignupGrantOnlyLocationPermission();
      context.pushNamed('signup_profile');
    }
  }

  void _updateLocationStatus(
    PermissionStatus status, {
    required bool openSettings,
  }) {
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      ref.read(locationProvider.notifier).updateLocationWithRequest();
      setState(() => _hasLocationPermission = true);
    } else if (status.isPermanentlyDenied && openSettings) {
      openAppSettings();
    }
  }

  void _updateContactsStatus(
    PermissionStatus status, {
    required bool openSettings,
  }) {
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      setState(() => _hasContactsPermission = true);
    } else if (status.isPermanentlyDenied && openSettings) {
      openAppSettings();
    }
  }
}
