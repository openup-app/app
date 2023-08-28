import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
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
        backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
        resizeToAvoidBottomInset: true,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Location & Contacts',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Text(
              'Howdy needs your location and contacts to help\nyou have the best experience.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color.fromRGBO(0x8D, 0x8D, 0x8D, 1.0),
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
                    .then(_updateLocationStatus)
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
                    .then(_updateContactsStatus)
                    .whenComplete(_checkPermissionsAndMaybeNavigate);
              },
            ),
            const Spacer(),
            const Text(
              'Howdy cares about your privacy. We will not\ntext, call or spam anyone from your contacts.',
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
    );
  }

  void _checkPermissionsAndMaybeNavigate() async {
    final statuses = await Future.wait([
      Permission.location.status,
      Permission.contacts.status,
    ]);
    if (!mounted) {
      return;
    }

    final locationStatus = statuses[0];
    final contactsStatus = statuses[1];
    _updateLocationStatus(locationStatus);
    _updateContactsStatus(contactsStatus);

    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (_hasLocationPermission && _hasContactsPermission && routeCurrent) {
      ref.read(analyticsProvider).trackSignupGrantPermissions();
      context.pushNamed('signup_name');
    }
  }

  void _updateLocationStatus(PermissionStatus status) {
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      setState(() => _hasLocationPermission = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _updateContactsStatus(PermissionStatus status) {
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      setState(() => _hasContactsPermission = true);
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}
