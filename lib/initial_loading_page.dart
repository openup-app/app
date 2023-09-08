import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/common.dart';

class InitialLoadingPage extends ConsumerStatefulWidget {
  const InitialLoadingPage({super.key});

  @override
  ConsumerState<InitialLoadingPage> createState() => _InitialLoadingPageState();
}

class _InitialLoadingPageState extends ConsumerState<InitialLoadingPage> {
  @override
  void initState() {
    super.initState();
    ref.listenManual(
      userProvider2,
      fireImmediately: true,
      (previous, next) {
        next.map(
          guest: (guest) {
            print('### Guest by default? ${guest.byDefault}');
            if (!guest.byDefault) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.goNamed('signup');
                }
              });
            }
          },
          signedIn: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.goNamed('discover');
              }
            });
          },
        );
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
