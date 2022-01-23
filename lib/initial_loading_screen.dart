import 'package:firebase_auth/firebase_auth.dart' hide UserMetadata;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/user_metadata.dart';
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
  bool _onboarded = false;

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
    } catch (e) {
      Navigator.of(context).pushReplacementNamed('error');
      return;
    }

    // Perform deep linking
    final deepLinked = await initializeNotifications(
      context: context,
      usersApi: usersApi,
    );

    // Standard app entry
    if (!deepLinked) {
      // TODO: Check if onboarded
      if (_onboarded) {
        Navigator.of(context).pushReplacementNamed('home');
      } else {
        Navigator.of(context).pushReplacementNamed('sign-up-info');
      }
    }
  }

  Future<void> _cacheData(UsersApi api, String uid) async {
    final result = await Future.wait([
      api.getUserMetadata(uid),
      api.getPublicProfile(uid),
      api.getPrivateProfile(uid),
      api.getFriendsPreferences(uid),
      api.getDatingPreferences(uid),
      api.getAllChatroomUnreadCounts(uid),
    ]);

    final userMetadata = result[0] as UserMetadata;

    if (mounted) {
      if (mounted) {
        setState(() {
          _onboarded = userMetadata.onboarded;
        });
      }
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
