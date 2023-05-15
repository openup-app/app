import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
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
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return AppLifecycle(
      onResumed: _checkPermissions,
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
            Align(
              alignment: Alignment.topCenter,
              child: Stack(
                alignment: Alignment.center,
                children: const [
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
              'BFF needs your location and contacts to help\nyou have the best experience.',
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
                Permission.location.request().then(_updateLocationStatus);
              },
            ),
            const SizedBox(height: 27),
            PermissionButton(
              icon: const Icon(Icons.import_contacts),
              label: const Text('Enable Contacts'),
              granted: _hasContactsPermission,
              onPressed: () {
                Permission.contacts.request().then(_updateContactsStatus);
              },
            ),
            const Spacer(),
            const Text(
              'BFF cares about your privacy. We will not\ntext, call or spam anyone from your contacts.',
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

  void _checkPermissions() {
    Permission.location.status.then((status) {
      _updateLocationStatus(status);
      _maybeNavigate();
    });
    Permission.contacts.status.then((status) {
      _updateContactsStatus(status);
      _maybeNavigate();
    });
  }

  void _updateLocationStatus(PermissionStatus status) {
    if (!mounted) {
      return;
    }

    if (status.isGranted || status.isLimited) {
      setState(() => _hasLocationPermission = true);
      _maybeNavigate();
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
      _maybeNavigate();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  void _maybeNavigate() {
    if (!mounted) {
      return;
    }

    final routeActive = ModalRoute.of(context)?.isActive == true;
    if (_hasLocationPermission && _hasContactsPermission && routeActive) {
      ref.read(mixpanelProvider).track("signup_grant_permissions");
      context.pushNamed('signup_name');
    }
  }
}
