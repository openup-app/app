import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
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
      userInitProvider,
      fireImmediately: true,
      (previous, next) {
        next.whenData((value) {
          value?.map(
            signedOut: (signedOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.goNamed('signin');
                }
              });
            },
            signedInWithoutAccount: (signedInWithoutAccount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.goNamed('signup');
                }
              });
            },
            signedInWithAccount: (signedInWithAccount) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.goNamed(
                      widget.redirect == null ? 'discover' : widget.redirect!);
                }
              });
            },
          );
        });
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
