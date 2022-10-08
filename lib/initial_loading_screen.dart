import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/notifications/ios_voip_handlers.dart' as ios_voip;
import 'package:openup/notifications/notifications.dart';
import 'package:openup/util/location_service.dart';

/// Page used for asynchronous initialization.
///
/// [notificationKey] is needed to access a context with a [Scaffold] ancestor.
class InitialLoadingScreen extends ConsumerStatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final bool needsOnboarding;

  const InitialLoadingScreen({
    GlobalKey? key,
    required this.navigatorKey,
    this.needsOnboarding = false,
  }) : super(key: key);

  @override
  ConsumerState<InitialLoadingScreen> createState() =>
      _InitialLoadingScreenState();
}

class _InitialLoadingScreenState extends ConsumerState<InitialLoadingScreen> {
  bool _deepLinked = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() async {
    // ConnectionService and CallKit
    initializeVoipHandlers(onDeepLink: _onDeepLink);

    await Firebase.initializeApp();
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final api = GetIt.instance.get<Api>();

    if (!mounted) {
      return;
    }

    // Verify user sign-in (will be navigated back here on success)
    if (user == null) {
      context.goNamed('signup');
      return;
    } else {
      try {
        api.authToken = await user.getIdToken(true);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          context.goNamed('signup');
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
      debugPrint(e.toString());
      if (mounted) {
        context.goNamed(
          'signup',
          extra: InitialLoadingScreenArguments(
            needsOnboarding: widget.needsOnboarding,
          ),
        );
      }
      return;
    }

    // Init notifications as early as possible for background notifications on iOS
    // (initial route is navigated to, but execution may stop due to user prompt or second navigation)
    await initializeNotifications(onDeepLink: _onDeepLink);

    if (!mounted) {
      return;
    }

    // Update push notifcation tokens
    final isIOS = Platform.isIOS;
    Future.wait([
      getNotificationToken(),
      if (isIOS) ios_voip.getVoipPushNotificationToken(),
    ]).then((tokens) {
      if (mounted) {
        api.addNotificationTokens(
          ref.read(userProvider).uid,
          fcmMessagingAndVoipToken: isIOS ? null : tokens[0],
          apnMessagingToken: isIOS ? tokens[0] : null,
          apnVoipToken: isIOS ? tokens[1] : null,
        );
      }
    });

    // Update location
    final profile = ref.read(userProvider).profile;
    final latLong = await LocationService().getLatLong();
    if (mounted) {
      await latLong.when(
        value: (lat, long) async {
          updateLocation(
            context: context,
            profile: profile!,
            notifier: notifier,
            latitude: lat,
            longitude: long,
          );
        },
        denied: () {
          // Nothing to do, request on Discover screen
        },
        failure: () {
          // Nothing to do, request on Discover screen
        },
      );
    }

    if (!mounted) {
      return;
    }

    if (mounted) {
      if (!_deepLinked && mounted) {
        // Standard app entry or sign up onboarding
        final noAudio = ref.read(userProvider).profile?.audio == null;
        if (widget.needsOnboarding || noAudio) {
          context.goNamed('onboarding');
        } else {
          context.goNamed('discover');
        }
      }
    }
  }

  void _onDeepLink(String path) {
    final context = widget.navigatorKey.currentContext;
    if (context != null) {
      _deepLinked = true;
      context.go(path);
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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/loading_icon.png',
          width: 200,
          height: 200,
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
