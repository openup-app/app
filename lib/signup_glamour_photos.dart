import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class SignupGlamourPhotos extends ConsumerStatefulWidget {
  const SignupGlamourPhotos({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupGlamourPhotos> createState() =>
      _SignupGlamourPhotosState();
}

class _SignupGlamourPhotosState extends ConsumerState<SignupGlamourPhotos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          leadingPadding: EdgeInsets.zero,
          trailingPadding: EdgeInsets.zero,
          leading: OpenupAppBarTextButton(
            onPressed: Navigator.of(context).pop,
            label: 'back',
          ),
          trailing: OpenupAppBarTextButton(
            onPressed: !_canSubmit(ref.watch(accountCreationParamsProvider))
                ? null
                : _submit,
            label: 'next',
          ),
        ),
      ),
      body: const SafeArea(
        child: SafeArea(
          child: _Photos(),
        ),
      ),
    );
  }

  bool _canSubmit(AccountCreationParams params) => params.photosValid;

  void _submit() {
    if (!_canSubmit(ref.read(accountCreationParamsProvider))) {
      return;
    }
    ref.read(analyticsProvider).trackSignupSubmitPhotos();
    context.pushNamed('signup_audio');
  }
}

class _Photos extends ConsumerStatefulWidget {
  const _Photos({super.key});

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
