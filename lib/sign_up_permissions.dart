import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:permission_handler/permission_handler.dart';

class SignUpPermissionsScreen extends StatefulWidget {
  const SignUpPermissionsScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPermissionsScreen> createState() => _SignUpPermissionsState();
}

class _SignUpPermissionsState extends State<SignUpPermissionsScreen> {
  static const _permissionGreen = Color.fromRGBO(0x06, 0xD9, 0x1B, 0.8);

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
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/signup_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: BackIconButton(),
                ),
              ),
              const Spacer(),
              Text(
                'openup',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 40, fontWeight: FontWeight.w700),
              ),
              Image.asset(
                'assets/images/app_logo.png',
              ),
              const Spacer(),
              Text(
                'Openup needs your location and\ncontacts to help you make the best\nconnections.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 16, fontWeight: FontWeight.w400),
              ),
              const Spacer(),
              Button(
                onPressed: () {
                  Permission.location.request().then(_updateLocationStatus);
                },
                child: RoundedRectangleContainer(
                  color: _hasLocationPermission ? _permissionGreen : null,
                  child: SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        const Icon(Icons.public),
                        const SizedBox(width: 13),
                        Text(
                          'Enable Location',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 19),
              Button(
                onPressed: () =>
                    Permission.contacts.request().then(_updateContactsStatus),
                child: RoundedRectangleContainer(
                  color: _hasContactsPermission ? _permissionGreen : null,
                  child: SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        const Icon(Icons.import_contacts),
                        const SizedBox(width: 13),
                        Text(
                          'Enable Contacts',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Openup cares about your privacy. We will not\ntext, call or spam anyone from your contacts.',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.8),
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

  void _maybeNavigate() {
    if (!mounted) {
      return;
    }
    if (_hasLocationPermission && _hasContactsPermission) {
      context.pushReplacementNamed('signup_phone');
    }
  }
}
