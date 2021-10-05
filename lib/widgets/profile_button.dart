import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/private_profile_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class ProfileButton extends StatelessWidget {
  final Color color;
  const ProfileButton({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => _showDebugUserDialog(context),
      child: Stack(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow,
                    offset: const Offset(0.0, 4.0),
                    blurRadius: 4.0,
                  ),
                ],
                color: color,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/profile.png',
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(boxShadow: [
                BoxShadow(
                  color: Theming.of(context).shadow,
                  offset: const Offset(0.0, 4.0),
                  blurRadius: 2.0,
                ),
              ], shape: BoxShape.circle, color: Theming.of(context).alertRed),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebugUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('My profile'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('User ID'),
              Text('${FirebaseAuth.instance.currentUser?.uid}'),
              const SizedBox(height: 8),
              const Text('Phone number'),
              Text('${FirebaseAuth.instance.currentUser?.phoneNumber}'),
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton(
                  onPressed: () => _showPrivateProfileDialog(context),
                  child: const Text('Update personal details'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final container = ProviderScope.containerOf(context);
                final usersApi = container.read(usersApiProvider);
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  await usersApi.deleteUser(uid);
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushReplacementNamed('initial-loading');
                }
              },
              child: const Text('Delete account'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('initial-loading');
              },
              child: const Text('Sign-out'),
            ),
          ],
        );
      },
    );
  }

  void _showPrivateProfileDialog(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final usersApi = container.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await usersApi.getPrivateProfile(uid);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) {
            return Scaffold(
              body: PrivateProfileScreen(
                initialProfile: profile,
              ),
            );
          },
        ),
      );
    }
  }
}
