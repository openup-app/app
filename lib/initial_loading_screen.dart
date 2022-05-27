import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/notifications.dart';
import 'package:openup/widgets/theming.dart';

/// Page used for asynchronous initialization.
///
/// [notificationKey] is needed to access a context with a [Scaffold] ancestor.
class InitialLoadingScreen extends ConsumerStatefulWidget {
  final GlobalKey scaffoldKey;
  final bool needsOnboarding;

  const InitialLoadingScreen({
    GlobalKey? key,
    required this.scaffoldKey,
    this.needsOnboarding = false,
  }) : super(key: key);

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
    final api = GetIt.instance.get<Api>();

    // Verify user sign-in (will be navigated back here on success)
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('sign-up');
      return;
    } else {
      try {
        api.authToken = await user.getIdToken();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'firebase_auth/user-not-found') {
          Navigator.of(context).pushReplacementNamed('sign-up');
          return;
        } else {
          rethrow;
        }
      }
    }

    final notifier = ref.read(userProvider.notifier);
    api.authToken = await user.getIdToken();
    notifier.uid(user.uid);

    // Begin caching
    try {
      await _cacheData(notifier.userState.uid);
    } catch (e) {
      print(e);
      Navigator.of(context).pushReplacementNamed(
        'error',
        arguments: InitialLoadingScreenArguments(
          needsOnboarding: widget.needsOnboarding,
        ),
      );
      return;
    }

    // Perform deep linking
    final deepLinked = await initializeNotifications(
      scaffoldKey: widget.scaffoldKey,
      userStateNotifier: notifier,
    );

    if (!deepLinked) {
      // Standard app entry or sign up onboarding
      if (widget.needsOnboarding) {
        Navigator.of(context).pushReplacementNamed('sign-up-info');
      } else {
        Navigator.of(context).pushReplacementNamed('lobby-list');
      }
    }
  }

  Future<void> _cacheData(String uid) {
    final api = GetIt.instance.get<Api>();
    final notifier = ref.read(userProvider.notifier);
    return Future.wait([
      api.getProfile(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache profile',
          (r) => notifier.profile(r),
        );
      }),
      api.getAttributes(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache attributes',
          (r) => notifier.attributes(r),
        );
      }),
      api.getInterests(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache interests',
          (r) => notifier.interests(r),
        );
      }),
      api.getFriendsPreferences(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache friends preferences',
          (r) => notifier.friendsPreferences(r),
        );
      }),
      api.getDatingPreferences(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to dating preferences',
          (r) => notifier.datingPreferences(r),
        );
      }),
      api.getUnreadMessageCount(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache unread message count',
          (r) => notifier.unreadMessageCount(r),
        );
      }),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.fromRGBO(0x01, 0x6E, 0x91, 1.0),
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/loading_icon.png',
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}

class InitialLoadingScreenArguments {
  final bool needsOnboarding;

  InitialLoadingScreenArguments({
    required this.needsOnboarding,
  });
}
