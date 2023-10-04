import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/photo_card.dart';
import 'package:openup/widgets/record.dart';
import 'package:openup/widgets/signup_background.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class SignupProfile extends ConsumerStatefulWidget {
  const SignupProfile({Key? key}) : super(key: key);

  @override
  ConsumerState<SignupProfile> createState() => _SignupProfileState();
}

class _SignupProfileState extends ConsumerState<SignupProfile> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: SignupBackground(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: constraints,
                    child: Center(
                      child: Transform.rotate(
                        angle: radians(-4),
                        child: PhotoCard(
                          width: constraints.maxWidth - (16 * 2),
                          height: constraints.maxHeight - (16 * 2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(1)),
                            boxShadow: [
                              BoxShadow(
                                offset: Offset(7, 8),
                                blurRadius: 30,
                                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
                              )
                            ],
                          ),
                          photo: Button(
                            onPressed: _showPhotoPicker,
                            child: Builder(
                              builder: (context) {
                                final photos = ref.watch(
                                    accountCreationParamsProvider
                                        .select((s) => s.photos));
                                if (photos == null || photos.isEmpty) {
                                  return Container(
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color.fromRGBO(0x25, 0x25, 0x25, 1.0),
                                          Color.fromRGBO(0x06, 0x06, 0x06, 1.0),
                                        ],
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo_outlined,
                                          size: 56,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Upload Photos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return CameraFlashGallery(
                                  slideshow: true,
                                  gallery: photos
                                      .map((e) => Uri.file(e.path))
                                      .toList(),
                                );
                              },
                            ),
                          ),
                          titleBuilder: (context) {
                            return Row(
                              children: [
                                Flexible(
                                  fit: FlexFit.loose,
                                  child: TextFormField(
                                    controller: _nameController,
                                    style: DefaultTextStyle.of(context).style,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    keyboardType: TextInputType.name,
                                    onChanged: ref
                                        .read(accountCreationParamsProvider
                                            .notifier)
                                        .name,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Name',
                                      hintStyle:
                                          DefaultTextStyle.of(context).style,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                Button(
                                  onPressed: _showAgePicker,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 8,
                                      right: 8,
                                      top: 3,
                                      bottom: 3,
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final age = ref.watch(
                                            accountCreationParamsProvider
                                                .select((s) => s.age));
                                        return switch (age) {
                                          null => const Text('Age'),
                                          _ => Text(age.toString()),
                                        };
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                          firstButton: Button(
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder: (context) {
                                  return CupertinoAlertDialog(
                                    title: const Text('Help'),
                                    content: const Text(
                                      'Sign up by entering your profile info on this card',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        onPressed: Navigator.of(context).pop,
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Center(
                              child: Text('Help'),
                            ),
                          ),
                          secondButton: Button(
                            onPressed: ref.watch(accountCreationParamsProvider
                                    .select((s) => !s.valid))
                                ? null
                                : _signUp,
                            child: const Center(
                              child: Text('Next'),
                            ),
                          ),
                          indicatorButton: Button(
                            onPressed: _showRecordPanel,
                            child: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                    color:
                                        Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'REC',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  child: const BackIconButton(
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _dismissKeyboard() => FocusScope.of(context).unfocus();

  void _showAgePicker() async {
    _dismissKeyboard();
    final age = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) {
        return SizedBox(
          height: 300,
          child: BlurredSurface(
            child: _AgePicker(
              initialAge: ref.read(accountCreationParamsProvider).age,
            ),
          ),
        );
      },
    );
    if (age != null && mounted) {
      ref.read(accountCreationParamsProvider.notifier).age(age);
    }
  }

  void _showGenderPicker() async {
    _dismissKeyboard();
    await showCupertinoModalPopup<Gender>(
      context: context,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(Gender.nonBinary),
              child: const Text('Non-binary'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(Gender.male),
              child: const Text('Male'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(Gender.female),
              child: const Text('Female'),
            ),
          ],
        );
      },
    );
  }

  void _showRecordPanel() async {
    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Voice Bio'),
      submitLabel: const Text('Tap to finish'),
    );
    if (!mounted || result == null) {
      return;
    }

    _onAudioRecorded(result.audio, result.duration);
  }

  void _onAudioRecorded(Uint8List audio, Duration duration) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(path.join(tempDir.path, 'collection_audio.m4a'));
    await file.writeAsBytes(audio);
    ref.read(accountCreationParamsProvider.notifier).audio(file);
  }

  void _showPhotoPicker() async {
    final photos = await selectPhotos(
      context,
    );
    if (mounted && photos != null) {
      ref.read(accountCreationParamsProvider.notifier).photos(photos);
    }
  }

  void _signUp() async {
    final result = await withBlockingModal(
      context: context,
      label: 'Creating account...',
      future: ref.read(accountCreationParamsProvider.notifier).signUp(),
    );

    if (!mounted || result == null) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => context.goNamed('signup_rules'),
    );
  }
}

class _AgePicker extends StatefulWidget {
  final int? initialAge;

  const _AgePicker({
    super.key,
    this.initialAge,
  });

  @override
  State<_AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<_AgePicker> {
  static const _minAge = 13;
  static const _maxAge = 99;
  static const _targetAge = 17;

  late final FixedExtentScrollController _scrollController;
  late int _age;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge ?? _targetAge;
    _scrollController =
        FixedExtentScrollController(initialItem: _age - _minAge);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.of(context).pop(_age);
        return Future.value(false);
      },
      child: CupertinoPicker(
        scrollController: _scrollController,
        itemExtent: 40,
        diameterRatio: 40,
        squeeze: 1.0,
        onSelectedItemChanged: (index) =>
            setState(() => _age = _minAge + index),
        selectionOverlay: const SizedBox.shrink(),
        children: [
          for (var age = _minAge; age <= _maxAge; age++)
            Center(
              child: Text(
                age.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
