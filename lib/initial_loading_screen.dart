import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/notifications.dart';

/// Page used for asynchronous initialization.
class InitialLoadingScreen extends ConsumerStatefulWidget {
  const InitialLoadingScreen({Key? key}) : super(key: key);

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

    final usersApi = ref.read(usersApiProvider);
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('sign-up');
      return;
    }

    final deepLinked = await initializeNotifications(
      context: context,
      usersApi: usersApi,
    );

    if (!deepLinked) {
      Navigator.of(context).pushReplacementNamed('home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
