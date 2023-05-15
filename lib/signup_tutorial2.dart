import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/signup_tutorial1.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';

class SignupTutorial2 extends ConsumerStatefulWidget {
  const SignupTutorial2({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SignupTutorial2> createState() => _SignupTutorial2();
}

class _SignupTutorial2 extends ConsumerState<SignupTutorial2> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF2, 0xF2, 0xF6, 1.0),
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.topCenter,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Align(
                  alignment: Alignment.centerLeft,
                  child: BackIconButton(
                    color: Colors.black,
                  ),
                ),
                Text(
                  'A Bad Photo Example',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.1),
                          offset: Offset(0, 11),
                          blurRadius: 26,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/tutorial_photo_bad.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, top: 48),
                    child: TutorialBubble.cross(
                      text: Text('Photos are poorly\nlit and blurry'),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: TutorialBubble.cross(
                      text: Text('Off center\n with no depth'),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 48),
                    child: TutorialBubble.cross(
                      text: Text('Unable to tell who\nyou are'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Button(
            onPressed: _submit,
            child: RoundedRectangleContainer(
              child: SizedBox(
                width: 171,
                height: 42,
                child: Center(
                  child: Text(
                    'Next',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w400),
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
    );
  }

  void _submit() async {
    ref.read(mixpanelProvider).track("signup_submit_tutorial2");
    context.pushNamed('signup_photos');
  }
}
