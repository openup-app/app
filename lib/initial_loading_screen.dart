import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
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

    if (user == null) {
      context.goNamed('signup');
      return;
    }

    for (var retryAttempt = 0; retryAttempt < 3; retryAttempt++) {
      debugPrint('FirebaseAuth getIdToken attempt $retryAttempt');
      try {
        api.authToken = await user.getIdToken(true);
        break;
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuth error ${e.code}');
        if (e.code == 'user-not-found') {
          context.goNamed('discover');
          return;
        } else if (e.code == 'unknown') {
          // Retry
          debugPrint('FirebaseAuth unknown error, retrying');
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        } else {
          rethrow;
        }
      }
    }

    final notifier = ref.read(userProvider.notifier);
    api.authToken = await user.getIdToken();
    final uid = user.uid;

    // Begin caching
    try {
      await _cacheData(uid);
    } catch (e) {
      debugPrint(e.toString());
      // TODO: Deal with onboarding
      if (mounted) {
        context.goNamed('discover');
      }
      return;
    }

    final profile = ref.read(userProvider2).map(
          guest: (_) => null,
          signedIn: (signedIn) => signedIn.profile,
        );
    if (profile != null) {
      ref.read(userProvider.notifier).uid(uid);
      ref.read(userProvider.notifier).profile(profile);
    }

    // Handle notifications as early as possible for background notifications.
    // On iOS, initial route is navigated to, but execution may stop due to
    // a user prompt or a second navigation
    await handleNotifications(onDeepLink: _onDeepLink);

    if (!mounted) {
      return;
    }

    // Update location
    if (profile != null) {
      final latLong = await LocationService().getLatLong();
      if (mounted) {
        await latLong.when(
          value: (lat, long) async {
            updateLocation(
              context: context,
              profile: profile,
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
    }

    if (!mounted) {
      return;
    }

    if (mounted) {
      if (!_deepLinked && mounted) {
        // Standard app entry or sign up onboarding
        final noCollection = profile?.collection.collectionId.isEmpty == true;
        if (widget.needsOnboarding || noCollection) {
          context.goNamed('signup_name');
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
    final notifier = ref.read(userProvider2.notifier);
    return Future.wait([
      api.getProfile(uid).then((value) {
        value.fold(
          (l) => throw 'Unable to cache profile',
          (r) => notifier.signedIn(r),
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
