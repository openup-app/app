import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/animation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/card_stack.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          center: Text('Profile'),
        ),
        toolbar: _TopTabs(),
      ),
      body: ref.watch(userProvider).map(
        guest: (_) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Log in to create a profile'),
                ElevatedButton(
                  onPressed: () => context.pushNamed('signup'),
                  child: const Text('Log in'),
                ),
              ],
            ),
          );
        },
        signedIn: (signedIn) {
          final profile = signedIn.account.profile;
          return SafeArea(
            child: Center(
              child: _ProfileStack(
                profile: profile,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopTabs extends StatelessWidget {
  const _TopTabs({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        child: Row(
          children: [
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('my_events'),
                child: const Center(
                  child: Text('My Meetups'),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: Color.fromRGBO(0x33, 0x330, 0x33, 1.0),
            ),
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('calendar'),
                child: const Center(
                  child: Text('Calendar'),
                ),
              ),
            ),
            const VerticalDivider(
              width: 1,
              color: Color.fromRGBO(0x33, 0x330, 0x33, 1.0),
            ),
            Expanded(
              child: Button(
                onPressed: () => context.pushNamed('settings'),
                child: const Center(
                  child: Text('Settings'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStack extends ConsumerStatefulWidget {
  final Profile profile;

  const _ProfileStack({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<_ProfileStack> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<_ProfileStack> {
  final _card1Key = GlobalKey();
  final _card2Key = GlobalKey();
  final _card3Key = GlobalKey();

  Timer? _animationTimer;

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = widget.profile.gallery;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = 193 * constraints.maxWidth / 390;
        final height = 298 * constraints.maxHeight / 600;
        return Stack(
          children: [
            Align(
              alignment: const Alignment(1.1, -0.3),
              child: Transform.rotate(
                angle: radians(7),
                child: _WiggleAnimation(
                  childKey: _card2Key,
                  child: _ProfilePhotoCard(
                    width: width,
                    height: height,
                    label: const Text('Photo #2'),
                    photo: gallery.length >= 2 ? gallery[1] : null,
                    onPressed: () => _updatePhoto(1),
                    onLongPress: gallery.length < 2
                        ? null
                        : () => _showDeletePhotoDialog(1),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.9, -1.0),
              child: Transform.rotate(
                angle: radians(-5),
                child: _WiggleAnimation(
                  childKey: _card1Key,
                  child: _ProfilePhotoCard(
                    width: width,
                    height: height,
                    label: const Text('Photo #1'),
                    photo: gallery.isNotEmpty ? gallery[0] : null,
                    onPressed: () => _updatePhoto(0),
                    onLongPress: gallery.isEmpty
                        ? null
                        : () => _showDeletePhotoDialog(0),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-1.0, 1.0),
              child: Transform.rotate(
                angle: radians(-8.5),
                child: _WiggleAnimation(
                  childKey: _card3Key,
                  child: _ProfilePhotoCard(
                    width: width,
                    height: height,
                    label: const Text('Photo #3'),
                    photo: gallery.length >= 3 ? gallery[2] : null,
                    onPressed: () => _updatePhoto(2),
                    onLongPress: gallery.length < 3
                        ? null
                        : () => _showDeletePhotoDialog(2),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.78, 0.58),
              child: Transform.rotate(
                angle: radians(-4),
                child: Button(
                  onPressed: () => _showRecordPanel(context),
                  child: Container(
                    width: 133,
                    height: 39,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      color: Color.fromRGBO(0xC6, 0x09, 0x09, 1.0),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Record Bio',
                        style: TextStyle(
                          fontFamily: 'Covered By Your Grace',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(0.85, 0.87),
              child: Transform.rotate(
                angle: radians(5.7),
                child: Button(
                  onPressed: () => _showPreview(context),
                  child: Container(
                    width: 133,
                    height: 39,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4,
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Preview',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: 'Covered By Your Grace',
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updatePhoto(int index) async {
    final photo = await selectPhoto(
      context,
      label: 'This photo will be used in your profile',
    );
    if (photo != null && mounted) {
      final notifier = ref.read(userProvider.notifier);
      final uploadFuture = notifier.updateGalleryPhoto(
        index: index,
        photo: photo,
      );
      await withBlockingModal(
        context: context,
        label: 'Updating photo',
        future: uploadFuture,
      );
    }
  }

  Future<void> _showRecordPanel(BuildContext context) async {
    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Voice Bio'),
      submitLabel: const Text('Tap to update'),
    );
    if (result == null) {
      return;
    }
    if (!mounted) {
      return;
    }

    final notifier = ref.read(userProvider.notifier);
    return withBlockingModal(
      context: context,
      label: 'Updating voice bio...',
      future: notifier.updateAudioBio(result.audio),
    );
  }

  void _showDeletePhotoDialog(int index) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete photo?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(true),
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (result == true && mounted) {
      await ref.read(userProvider.notifier).deleteGalleryPhoto(index);
    }
  }

  void _showPreview(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoModalPopupRoute(
        builder: (context) {
          return _PreviewPage(
            profile: DiscoverProfile(
              profile: widget.profile,
              location: const UserLocation(
                latLong: LatLong(latitude: 0, longitude: 0),
                radius: 0,
                visibility: LocationVisibility.private,
              ),
              favorite: false,
            ),
          );
        },
      ),
    );
  }
}

class _PreviewPage extends StatefulWidget {
  final DiscoverProfile profile;

  const _PreviewPage({
    super.key,
    required this.profile,
  });

  @override
  State<_PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<_PreviewPage> {
  final _profileBuilderKey = GlobalKey<ProfileBuilderState>();
  bool _play = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          leading: OpenupAppBarCloseButton(),
          center: Text('Preview'),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ProfileBuilder(
            key: _profileBuilderKey,
            profile: widget.profile.profile,
            play: _play,
            builder: (context, playbackState, playbackInfoStream) {
              return CardStack(
                width: constraints.maxWidth,
                items: [widget.profile],
                onChanged: (_) {},
                itemBuilder: (context, item, key) {
                  return PhotoCardWiggle(
                    childKey: key,
                    child: PhotoCardProfile(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      profile: item,
                      distance: 2,
                      playbackState: playbackState,
                      playbackInfoStream: playbackInfoStream,
                      onPlay: () {
                        _profileBuilderKey.currentState?.play();
                        setState(() => _play = true);
                      },
                      onPause: () {
                        _profileBuilderKey.currentState?.pause();
                        setState(() => _play = false);
                      },
                      onMessage: () {},
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget label;
  final String? photo;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;

  const _ProfilePhotoCard({
    super.key,
    required this.width,
    required this.height,
    required this.label,
    required this.photo,
    required this.onPressed,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      onLongPressStart: onLongPress,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.only(
          left: 16,
          top: 16,
          right: 16,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(2)),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  if (photo == null) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_a_photo,
                          size: 48,
                          color: Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
                        ),
                      ),
                    );
                  }
                  return Image.network(
                    photo!,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            SizedBox(
              height: 48,
              child: Center(
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'Covered By Your Grace',
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  child: label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WiggleAnimation extends StatelessWidget {
  final GlobalKey childKey;
  final Widget child;

  const _WiggleAnimation({
    super.key,
    required this.childKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return WiggleBuilder(
      key: childKey,
      seed: childKey.hashCode,
      builder: (context, child, wiggle) {
        final offset = Offset(
          wiggle(frequency: 0.3, amplitude: 20),
          wiggle(frequency: 0.3, amplitude: 20),
        );

        final rotationZ = wiggle(frequency: 0.5, amplitude: radians(6));
        final rotationY = wiggle(frequency: 0.5, amplitude: radians(15));
        const perspectiveDivide = 0.002;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, perspectiveDivide)
          ..rotateY(rotationY)
          ..rotateZ(rotationZ);
        return Transform.translate(
          offset: offset,
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
