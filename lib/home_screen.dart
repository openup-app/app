import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/loading_dialog.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _cachingStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_cachingStarted) {
      return;
    }
    _cachingStarted = true;

    VoidCallback? popDialog;
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      popDialog = showBlockingModalDialog(
        context: context,
        builder: (_) => const Loading(),
      );
    });

    final container = ProviderScope.containerOf(context);
    final api = container.read(usersApiProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw 'No user is logged in';
    }

    _cacheData(api, uid).then((_) => _updateLocation(api, uid)).then((_) {
      if (mounted) {
        popDialog?.call();
      }
    });
  }

  Future<void> _cacheData(UsersApi api, String uid) {
    return Future.wait([
      api.getPublicProfile(uid),
      api.getPrivateProfile(uid),
      api.getFriendsPreferences(uid),
      api.getDatingPreferences(uid),
    ]);
  }

  Future<void> _updateLocation(UsersApi api, String uid) async {
    final location = Location();
    try {
      final result = await location.requestPermission();
      if (result == PermissionStatus.granted ||
          result == PermissionStatus.grantedLimited) {
        final data = await location.getLocation();
        if (data.latitude != null && data.longitude != null) {
          final profile = await api.getPrivateProfile(uid);
          api.updatePrivateProfile(
            uid,
            profile.copyWith(
              location: LatLong(
                lat: data.latitude ?? 0,
                long: data.longitude ?? 0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () =>
                    Navigator.of(context).pushNamed('dating-solo-double'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromARGB(0xFF, 0xFF, 0x83, 0x83),
                        Theming.of(context).datingRed1,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.only(left: 40),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'blind\ndating',
                          textAlign: TextAlign.left,
                          style: Theming.of(context).text.large,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 120,
                        child: Image.asset(
                          'assets/images/heart.png',
                          fit: BoxFit.fitHeight,
                        ),
                      ),
                      const SizedBox(height: 100),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Button(
                onPressed: () =>
                    Navigator.of(context).pushNamed('friends-solo-double'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theming.of(context).friendBlue1,
                        Theming.of(context).friendBlue2,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      const SizedBox(height: 120),
                      const SizedBox(
                        height: 120,
                        child: MaleFemaleConnectionImage(),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.only(left: 40),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'make\nfriends',
                          textAlign: TextAlign.left,
                          style: Theming.of(context).text.large,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          right: MediaQuery.of(context).padding.right + 16,
          child: const ProfileButton(
            color: Color.fromARGB(0xFF, 0xFF, 0xAF, 0xAF),
          ),
        ),
      ],
    );
  }
}
