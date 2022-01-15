import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/theming.dart';

/// Page used for asynchronous initialization.
class InitialLoadingScreen extends ConsumerStatefulWidget {
  const InitialLoadingScreen({Key? key}) : super(key: key);

  @override
  _InitialLoadingScreenState createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends ConsumerState<InitialLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    await Firebase.initializeApp();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    // Verify user sign-in (will be navigated back here on success)
    final usersApi = ref.read(usersApiProvider);
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('sign-up');
      return;
    }
    usersApi.uid = user.uid;

    // Begin caching
    try {
      await _cacheData(usersApi, user.uid);
      await _updateLocation(usersApi, user.uid);
    } catch (e) {
      Navigator.of(context).pushReplacementNamed('error');
      return;
    }

    // Perform deep linking
    final deepLinked = await initializeNotifications(
      context: context,
      usersApi: usersApi,
    );

    // Stardand app entry
    if (!deepLinked) {
      // TODO: Check if onboarded
      final onboarded = false;
      if (onboarded) {
        Navigator.of(context).pushReplacementNamed('home');
      } else {
        Navigator.of(context).pushReplacementNamed('sign-up-info');
      }
    }
  }

  Future<void> _cacheData(UsersApi api, String uid) async {
    await Future.wait([
      api.getPublicProfile(uid),
      api.getPrivateProfile(uid),
      api.getFriendsPreferences(uid),
      api.getDatingPreferences(uid),
      api.getAllChatroomUnreadCounts(uid),
    ]);
  }

  Future<void> _updateLocation(UsersApi api, String uid) async {
    final location = Location();
    try {
      final result = await location.requestPermission();
      if (result == PermissionStatus.granted ||
          result == PermissionStatus.grantedLimited) {
        final data = await location.getLocation();
        if (data.latitude != null && data.longitude != null) {
          final profile = await api.getPrivateProfile(uid);
          api.updatePrivateProfile(
            uid,
            profile.copyWith(
              location: LatLong(
                lat: data.latitude ?? 0,
                long: data.longitude ?? 0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
            Text(
              'Loading Openup...',
              style:
                  Theming.of(context).text.body.copyWith(color: Colors.black),
            )
          ],
        ),
      ),
    );
  }
}
