import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignUpGender extends ConsumerStatefulWidget {
  const SignUpGender({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignUpGender> createState() => _SignUpGenderState();
}

class _SignUpGenderState extends ConsumerState<SignUpGender> {
  bool _uploading = false;
  Gender? _gender;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/signup_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: MediaQuery.of(context).padding.top,
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: BackIconButton(),
              ),
            ),
            const Spacer(),
            Text(
              'What\'s your gender?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 36),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RadioButton(
                    label: 'Male',
                    selected: _gender == Gender.male,
                    onPressed: () => setState(() => _gender = Gender.male),
                  ),
                  _RadioButton(
                    label: 'Female',
                    selected: _gender == Gender.female,
                    onPressed: () => setState(() => _gender = Gender.female),
                  ),
                  _RadioButton(
                    label: 'Non-Binary',
                    selected: _gender == Gender.nonBinary,
                    onPressed: () => setState(() => _gender = Gender.nonBinary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Button(
              onPressed: _uploading || _gender == null ? null : _submit,
              child: RoundedRectangleContainer(
                child: SizedBox(
                  width: 171,
                  child: Center(
                    child: _uploading
                        ? const LoadingIndicator(size: 24)
                        : Text(
                            'Next',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.white),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: MediaQuery.of(context).padding.bottom,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    final gender = _gender;
    if (gender == null) {
      return;
    }
    setState(() => _uploading = true);

    final result = await updateGender(
      context: context,
      ref: ref,
      gender: gender,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        GetIt.instance.get<Mixpanel>()
          ..track("sign_up_submit_gender")
          ..getPeople().set('gender', gender.name);
        // context.goNamed('signup');
      },
    );

    setState(() => _uploading = false);
  }
}

class _RadioButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  const _RadioButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 19, fontWeight: FontWeight.w300)),
            ),
            CustomPaint(
              painter: _RadioButtonPainter(
                selected: selected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioButtonPainter extends CustomPainter {
  final bool selected;

  const _RadioButtonPainter({
    required this.selected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      9,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 1
        ..style = selected ? PaintingStyle.fill : PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _RadioButtonPainter oldDelegate) {
    return oldDelegate.selected == selected;
  }
}
