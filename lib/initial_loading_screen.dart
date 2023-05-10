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
    if (!mounted) {
      return;
    }

    // Update location
    final latLong = await LocationService().getLatLong();
    final latLongValue = latLong.map(
      value: (value) {
        ref.read(locationProvider.notifier).update(value);
        return value;
      },
      denied: (_) {
        // Nothing to do, request on Discover screen
        return null;
      },
      failure: (_) {
        // Nothing to do, request on Discover screen
        return null;
      },
    );
    if (!mounted) {
      return;
    }

    // Anonymous usage of the app
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.goNamed('discover');
      return;
    }

    _setupApiAuthToken(user);

    // Get user profile
    final getAccountResult = await getAccount();
    if (!mounted) {
      return;
    }

    final navigate = getAccountResult.map(
      logIn: (_) => false,
      signUp: (_) => true,
      retry: (_) => false,
    );
    if (navigate) {
      context.goNamed('signup');
      return;
    }

    getAccountResult.when(
      logIn: (profile) {
        ref.read(userProvider.notifier).uid(profile.uid);
        ref.read(userProvider.notifier).profile(profile);
        ref.read(userProvider2.notifier).signedIn(profile);
        if (latLongValue != null) {
          updateLocation(
            latitude: latLongValue.latitude,
            longitude: latLongValue.longitude,
          );
        }
      },
      signUp: () {
        // Already handled
      },
      retry: () {
        // TODO: Handle error
      },
    );

    // Handle notifications as early as possible for background notifications.
    // On iOS, initial route is navigated to, but execution may stop due to
    // a user prompt or a second navigation
    await handleNotifications(onDeepLink: _onDeepLink);
    if (!mounted) {
      return;
    }

    if (!_deepLinked) {
      // Standard app entry or sign up onboarding
      if (widget.needsOnboarding) {
        context.goNamed('signup_name');
      } else {
        context.goNamed('discover');
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

  Future<void> _setupApiAuthToken(User user) async {
    final api = GetIt.instance.get<Api>();
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
