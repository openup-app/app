import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/scaffold.dart';

class SignupGlamourAge extends ConsumerStatefulWidget {
  const SignupGlamourAge({super.key});

  @override
  ConsumerState<SignupGlamourAge> createState() => _SignupGlamourAgeState();
}

class _SignupGlamourAgeState extends ConsumerState<SignupGlamourAge> {
  static const _kMinimumAllowedAge = 17;

  @override
  void initState() {
    super.initState();
    if (ref.read(accountCreationParamsProvider).age == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(accountCreationParamsProvider.notifier)
              .age(_kMinimumAllowedAge);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
      body: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 89,
            left: 0,
            right: 0,
            child: const GradientMask(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 29),
                child: AutoSizeText(
                  'What\'s your\nage?',
                  maxLines: 2,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const Center(
            child: SizedBox(
              width: 34,
              height: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.fromRGBO(0x29, 0x29, 0x29, 1.0),
                  borderRadius: BorderRadius.all(
                    Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: _AgePicker(
              initialAge: _kMinimumAllowedAge,
              onChanged: ref.read(accountCreationParamsProvider.notifier).age,
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(AccountCreationParams params) => params.ageValid;

  void _submit() {
    if (!_canSubmit(ref.read(accountCreationParamsProvider))) {
      return;
    }
    final analytics = ref.read(analyticsProvider);
    analytics.trackSignupSubmitAge();
    context.pushNamed('signup_photos');
  }
}

class _AgePicker extends StatefulWidget {
  final int initialAge;
  final ValueChanged<int> onChanged;

  const _AgePicker({
    super.key,
    required this.initialAge,
    required this.onChanged,
  });

  @override
  State<_AgePicker> createState() => _AgePickerState();
}

class _AgePickerState extends State<_AgePicker> {
  static const _minAge = 13;
  static const _maxAge = 99;

  late final FixedExtentScrollController _scrollController;
  late int _age;

  @override
  void initState() {
    super.initState();
    _age = widget.initialAge;
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
    return RotatedBox(
      quarterTurns: -1,
      child: GradientMask(
        gradient: const RadialGradient(
          stops: [
            0.5,
            1.0,
          ],
          colors: [
            Colors.white,
            Colors.transparent,
          ],
        ),
        child: CupertinoPicker(
          scrollController: _scrollController,
          itemExtent: 36,
          diameterRatio: 36,
          squeeze: 1.0,
          onSelectedItemChanged: (index) {
            setState(() => _age = _minAge + index);
            widget.onChanged(_age);
          },
          selectionOverlay: const SizedBox.shrink(),
          children: [
            for (var age = _minAge; age <= _maxAge; age++)
              Center(
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Text(
                    age.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
