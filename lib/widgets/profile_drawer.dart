import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/public_profile_screen.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_photo.dart';
import 'package:openup/widgets/theming.dart';
import 'package:openup/widgets/unread_message_badge.dart';

class ProfileDrawer extends ConsumerWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const iconColor = Color.fromARGB(0xFF, 0xFC, 0x7A, 0x7A);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 150,
          sigmaY: 150,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16),
            Flexible(
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 674 / 899,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(40)),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.50),
                            offset: Offset(-2.0, 4.0),
                            blurRadius: 20,
                          ),
                        ],
                        color: Colors.white,
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final photo = ref.watch(profileProvider)?.photo;
                          if (photo == null) {
                            return const DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(40)),
                                color: Color.fromRGBO(0xC4, 0xC4, 0xC4, 0.5),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 48,
                              ),
                            );
                          }
                          return ProfilePhoto(
                            url: photo,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                ref.read(usersApiProvider).publicProfile?.name ?? '',
                style: Theming.of(context).text.bodySecondary.copyWith(
                  fontSize: 24,
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
                StreamBuilder<int>(
                  stream: ref.read(usersApiProvider).unreadChatMessageSumStream,
                  initialData: 0,
                  builder: (context, snapshot) {
                    final sum = snapshot.requireData;
                    return _MenuButton(
                      icon: SvgPicture.asset(
                        'assets/images/connections_icon.svg',
                        color: iconColor,
                        width: 32,
                        height: 32,
                        fit: BoxFit.scaleDown,
                      ),
                      title: 'connections',
                      badgeNumber: sum,
                      onPressed: () =>
                          Navigator.of(context).pushNamed('connections'),
                    );
                  },
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
                  onPressed: () =>
                      Navigator.of(context).pushNamed('account-settings'),
                ),
              ],
            ),
            const Spacer(flex: 1),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
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
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0.0, 4.0),
              blurRadius: 4.0,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.08),
            ),
          ],
        ),
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
                  if (badgeNumber != null && badgeNumber != 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      width: 22,
                      height: 22,
                      child: UnreadMessageBadge(
                        count: badgeNumber!,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              title,
              style: Theming.of(context).text.bodySecondary.copyWith(
                fontSize: 24,
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
