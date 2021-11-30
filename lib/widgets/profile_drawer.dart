import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconColor = Color.fromARGB(0xFF, 0xFC, 0x7A, 0x7A);
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 3,
            child: Button(
              onPressed: () {
                final usersApi = ref.watch(usersApiProvider);
                Navigator.of(context).pushNamed(
                  'public-profile',
                  arguments: PublicProfileArguments(
                    publicProfile: usersApi.publicProfile!,
                    editable: true,
                  ),
                );
              },
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 60,
                  minHeight: 60,
                ),
                clipBehavior: Clip.hardEdge,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Theming.of(context).shadow.withOpacity(0.5),
                      offset: const Offset(0.0, 4.0),
                      blurRadius: 16,
                    ),
                  ],
                  color: Colors.white,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final photo = ref.watch(profileProvider).state?.photo;
                    return ProfilePhoto(url: photo);
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              ref.read(usersApiProvider).publicProfile?.name ?? '',
              style: Theming.of(context).text.bodySecondary.copyWith(
                fontSize: 26,
                shadows: [
                  Shadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 6,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              _MenuButton(
                icon: SvgPicture.asset(
                  'assets/images/connections_icon.svg',
                  color: iconColor,
                  width: 32,
                  height: 32,
                  fit: BoxFit.scaleDown,
                ),
                title: 'connections',
                badgeNumber: 4,
                onPressed: () => Navigator.of(context).pushNamed('connections'),
              ),
              _MenuButton(
                icon: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: Image.asset(
                      'assets/images/preferences.png',
                      color: iconColor,
                    ),
                  ),
                ),
                title: 'my profile',
                onPressed: () => _showPrivateProfileDialog(context),
              ),
              _MenuButton(
                icon: SvgPicture.asset(
                  'assets/images/rekindle_icon.svg',
                  color: iconColor,
                  width: 32,
                  height: 32,
                  fit: BoxFit.scaleDown,
                ),
                title: 'rekindle',
                onPressed: () => Navigator.of(context).pushNamed('rekindle'),
              ),
              _MenuButton(
                icon: SvgPicture.asset(
                  'assets/images/support_icon.svg',
                  color: iconColor,
                  width: 32,
                  height: 32,
                  fit: BoxFit.scaleDown,
                ),
                title: 'account & support',
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(flex: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: () async {
                        final container = ProviderScope.containerOf(context);
                        final usersApi = container.read(usersApiProvider);
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await usersApi.deleteUser(uid);
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context)
                              .pushReplacementNamed('initial-loading');
                        }
                      },
                      child: const Text('Delete account'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context)
                            .pushReplacementNamed('initial-loading');
                      },
                      child: const Text('Sign-out'),
                    ),
                  ],
                ),
                Text('${FirebaseAuth.instance.currentUser?.uid}'),
                Text('${FirebaseAuth.instance.currentUser?.phoneNumber}'),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom,
          ),
        ],
      ),
    );
  }

  void _showPrivateProfileDialog(BuildContext context) async {
    final container = ProviderScope.containerOf(context);
    final usersApi = container.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final profile = await usersApi.getPrivateProfile(uid);
      Navigator.of(context).pushNamed('private-profile', arguments: profile);
    }
  }
}

class _MenuButton extends StatelessWidget {
  final Widget icon;
  final int? badgeNumber;
  final String title;
  final VoidCallback onPressed;

  const _MenuButton({
    Key? key,
    required this.icon,
    this.badgeNumber,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        height: 88,
        color: Colors.white.withOpacity(0.3),
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Theming.of(context).shadow,
                          blurRadius: 4,
                          offset: const Offset(0.0, 2.0),
                        ),
                      ],
                    ),
                    child: icon,
                  ),
                  if (badgeNumber != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(0xFF, 0xDC, 0x35, 0x35),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            badgeNumber.toString(),
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 16, fontWeight: FontWeight.normal),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              title,
              style: Theming.of(context).text.bodySecondary.copyWith(
                shadows: [
                  Shadow(
                    color: Theming.of(context).shadow,
                    blurRadius: 6,
                    offset: const Offset(0.0, 2.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
