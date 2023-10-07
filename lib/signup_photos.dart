import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/animation.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/signup_background.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class SignupPhotos extends ConsumerStatefulWidget {
  const SignupPhotos({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupPhotos> createState() => _SignupPhotosState();
}

class _SignupPhotosState extends ConsumerState<SignupPhotos> {
  bool _continueVisible = false;
  bool _canContinue = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SignupBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  SafeArea(
                    child: _Photos(
                      onCanContinueChanged: (canContinue) =>
                          setState(() => _canContinue = canContinue),
                    ),
                  )
                      .animate(
                        onComplete: (_) =>
                            setState(() => _continueVisible = true),
                      )
                      .slideY(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutQuart,
                        begin: 1,
                        end: 0,
                      ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset('assets/images/cat_paw.png')
                        .animate()
                        .slideY(
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutQuart,
                          begin: 1,
                          end: 0,
                        )
                        .slideY(
                          delay: const Duration(milliseconds: 1000),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOut,
                          begin: 0,
                          end: 1,
                        ),
                  ),
                  Positioned(
                    right: 24,
                    bottom: 40,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 700),
                      opacity: _continueVisible ? 1.0 : 0.0,
                      child: SignupNextButton(
                        onPressed: !_canContinue ? null : _submit,
                        child: const Text('Next'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    ref.read(analyticsProvider).trackSignupSubmitPhotos();
    context.pushNamed('signup_name_age');
  }
}

class _Photos extends ConsumerStatefulWidget {
  final void Function(bool canContinue) onCanContinueChanged;

  const _Photos({
    super.key,
    required this.onCanContinueChanged,
  });

  @override
  ConsumerState<_Photos> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends ConsumerState<_Photos> {
  late final List<File?> _photos;

  @override
  void initState() {
    super.initState();
    final photos = ref.read(accountCreationParamsProvider).photos ?? [];
    if (photos.length < 3) {
      _photos = List.generate(3, (index) => null)
        ..replaceRange(0, photos.length, photos);
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) {
          widget.onCanContinueChanged(_photos.whereType<File>().isNotEmpty);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const width = 193.0;
        const height = 298.0;
        return Stack(
          children: [
            Align(
              alignment: const Alignment(1.0, 0.0),
              child: Transform.rotate(
                angle: radians(2.45),
                child: _ProfilePhotoCard(
                  width: width,
                  height: height,
                  label: const Text('Photo #2'),
                  photo: _photos.length >= 2 ? _photos[1] : null,
                  onPressed: () => _updatePhoto(1),
                  onLongPress: _photos[1] == null
                      ? null
                      : () => _showDeletePhotoDialog(1),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.6, -1.0),
              child: Transform.rotate(
                angle: radians(23),
                child: _ProfilePhotoCard(
                  width: width,
                  height: height,
                  label: const Text('Photo #1'),
                  photo: _photos.isNotEmpty ? _photos[0] : null,
                  onPressed: () => _updatePhoto(0),
                  onLongPress: _photos[0] == null
                      ? null
                      : () => _showDeletePhotoDialog(0),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.9, 0.8),
              child: Transform.rotate(
                angle: radians(-8),
                child: _ProfilePhotoCard(
                  width: width,
                  height: height,
                  label: const Text('Photo #3'),
                  photo: _photos.length >= 3 ? _photos[2] : null,
                  onPressed: () => _updatePhoto(2),
                  onLongPress: _photos[2] == null
                      ? null
                      : () => _showDeletePhotoDialog(2),
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
      setState(() => _photos[index] = photo);
      ref
          .read(accountCreationParamsProvider.notifier)
          .photos(_photos.whereType<File>().toList());
      widget.onCanContinueChanged(_photos.whereType<File>().isNotEmpty);
    }
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
      setState(() => _photos[index] = null);
      ref
          .read(accountCreationParamsProvider.notifier)
          .photos(_photos.whereType<File>().toList());
      widget.onCanContinueChanged(_photos.whereType<File>().isNotEmpty);
    }
  }
}

class _ProfilePhotoCard extends StatelessWidget {
  final double width;
  final double height;
  final Widget label;
  final File? photo;
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
          left: 13,
          top: 13,
          right: 13,
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
                    return const DecoratedBox(
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(0x25, 0x25, 0x25, 1.0)),
                    );
                  }
                  return Image.file(
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
