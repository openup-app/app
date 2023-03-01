import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/widgets/app_lifecycle.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/common.dart';
import 'package:permission_handler/permission_handler.dart';

class SignUpPermissionsScreen extends StatefulWidget {
  const SignUpPermissionsScreen({Key? key}) : super(key: key);

  @override
  State<SignUpPermissionsScreen> createState() => _SignUpPermissionsState();
}

class _SignUpPermissionsState extends State<SignUpPermissionsScreen> {
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
              PermissionButton(
                icon: const Icon(Icons.public),
                label: const Text('Enable Location'),
                granted: _hasLocationPermission,
                onPressed: () {
                  Permission.location.request().then(_updateLocationStatus);
                },
              ),
              const SizedBox(height: 19),
              PermissionButton(
                icon: const Icon(Icons.import_contacts),
                label: const Text('Enable Contacts'),
                granted: _hasContactsPermission,
                onPressed: () {
                  Permission.location.request().then(_updateContactsStatus);
                },
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
