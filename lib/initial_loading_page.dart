import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/after_party_waitlist.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/waitlist/waitlist_provider.dart';
import 'package:openup/widgets/common.dart';

class InitialLoadingPage extends ConsumerStatefulWidget {
  final String? redirect;

  const InitialLoadingPage({
    super.key,
    this.redirect,
  });

  @override
  ConsumerState<InitialLoadingPage> createState() => _InitialLoadingPageState();
}

class _InitialLoadingPageState extends ConsumerState<InitialLoadingPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      appInitProvider,
      fireImmediately: true,
      (previous, next) {
        if (!next.hasValue) {
          return;
        }

        final appInit = next.value;
        if (appInit == null) {
          _goToSignIn();
        } else {
          appInit.accountState.map(
            account: (account) => _goToMainApp(widget.redirect),
            needsSignup: (needsSignup) =>
                _accessDenied(appInit, video: needsSignup.video),
            none: (_) => _accessDenied(appInit),
          );
        }
      },
    );
  }

  void _goToSignIn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed('signin');
      }
    });
  }

  void _goToMainApp(String? redirect) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(redirect ?? 'discover');
      }
    });
  }

  void _goToBeforePartyWaitlist(WaitlistUser waitlistUser) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(
          'waitlist',
          queryParameters: {
            'uid': waitlistUser.uid,
            'email': waitlistUser.email,
          },
        );
      }
    });
  }

  void _goToAfterPartyWaitlist(List<String> sampleVideos) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(
          'after_party_waitlist',
          extra: AfterPartyWaitlistParams(sampleVideos),
        );
      }
    });
  }

  void _goToAfterPartyProcessing() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed('after_party_processing');
      }
    });
  }

  void _goToSignup(String video) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.goNamed(
          'signup',
          queryParameters: {video: video},
        );
      }
    });
  }

  void _accessDenied(AppInit appInit, {String? video}) {
    if (!appInit.appAvailability.partyComplete) {
      _goToBeforePartyWaitlist(appInit.waitlistUser);
    } else {
      if (video == null) {
        _goToAfterPartyWaitlist(appInit.appAvailability.sampleVideos);
      } else {
        if (appInit.appAvailability.appLocked) {
          _goToAfterPartyProcessing();
        } else {
          _goToSignup(video);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingIndicator(),
    );
  }
}
