import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      waitlistProvider,
      fireImmediately: true,
      (previous, next) {
        if (next == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.goNamed('signin');
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.goNamed(
                'waitlist',
                queryParameters: {
                  'uid': next.uid,
                  'email': next.email,
                },
              );
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: LoadingIndicator(),
    );
  }
}
