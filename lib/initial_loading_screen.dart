import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide UserMetadata;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/user_metadata.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/theming.dart';

/// Page used for asynchronous initialization.
///
/// [notificationKey] is needed to access a context with a [Scaffold] ancestor.
class InitialLoadingScreen extends ConsumerStatefulWidget {
  final GlobalKey notificationKey;
  const InitialLoadingScreen({
    GlobalKey? key,
    required this.notificationKey,
  }) : super(key: key);

  @override
  _InitialLoadingScreenState createState() => _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends ConsumerState<InitialLoadingScreen> {
  bool _onboarded = false;
  StreamSubscription? _idTokenRefreshSubscription;

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
    if (user == null) {
      initUsersApi(
        host: host,
        port: webPort,
      );
      Navigator.of(context).pushReplacementNamed('sign-up');
      return;
    } else {
      try {
        final token = await user.getIdToken();
        initUsersApi(
          host: host,
          port: webPort,
          authToken: token,
        );
      } on FirebaseAuthException catch (e) {
        print('code is ${e.code}');
        if (e.code == 'firebase_auth/user-not-found') {
          // Sign up instead
          initUsersApi(
            host: host,
            port: webPort,
          );
          Navigator.of(context).pushReplacementNamed('sign-up');
          return;
        } else {
          rethrow;
        }
      }
    }

    final usersApi = ref.read(usersApiProvider);
    usersApi.authToken = await user.getIdToken();
    usersApi.uid = user.uid;

    // Firebase ID token refresh
    _idTokenRefreshSubscription =
        FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user != null) {
        usersApi.authToken = await user.getIdToken();
      }
    });

    // Begin caching
    try {
      await _cacheData(usersApi, user.uid);
    } catch (e, s) {
      print(e);
      print(s);
      Navigator.of(context).pushReplacementNamed('error');
      return;
    }

    // Perform deep linking
    final deepLinked = await initializeNotifications(
      key: widget.notificationKey,
      usersApi: usersApi,
    );

    // Standard app entry
    if (!deepLinked) {
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
  void dispose() {
    _idTokenRefreshSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 32),
          Text(
            'Loading Openup...',
            style: Theming.of(context).text.body.copyWith(color: Colors.black),
          )
        ],
      ),
    );
  }
}
