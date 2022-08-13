import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/theming.dart';

class SignUpWelcomeInfoScreen extends ConsumerWidget {
  const SignUpWelcomeInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProvider).profile!;
    final name = profile.name;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.of(context).pushReplacementNamed('home');
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0x00, 0x51, 0x6E, 1.0),
              Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
            ],
          ),
          boxShadow: [
            const BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 11,
              blurStyle: BlurStyle.inner,
            ),
            Theming.of(context).boxShadow,
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 357),
                      child: DefaultTextStyle(
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            height: 1.7),
                        child: Builder(
                          builder: (context) {
                            return RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'Hey $name if you ever had a hard time making friends and want a place to meet new people, this is it. ',
                                    style: DefaultTextStyle.of(context).style,
                                  ),
                                  TextSpan(
                                    text: 'Everyone is welcome here',
                                    style: DefaultTextStyle.of(context)
                                        .style
                                        .copyWith(
                                            color: const Color.fromRGBO(
                                                0xFF, 0x6E, 0x6E, 1.0)),
                                  ),
                                  TextSpan(
                                    text:
                                        ', no matter your age, race, sex, sexuality, relationship status, all that we ask is that you ',
                                    style: DefaultTextStyle.of(context).style,
                                  ),
                                  TextSpan(
                                    text: 'be kind to one another. ',
                                    style: DefaultTextStyle.of(context).style,
                                  ),
                                  TextSpan(
                                    text: 'This is a place to ',
                                    style: DefaultTextStyle.of(context).style,
                                  ),
                                  TextSpan(
                                    text: 'comfortably meet new people.',
                                    style: DefaultTextStyle.of(context)
                                        .style
                                        .copyWith(
                                            color: const Color.fromRGBO(
                                                0xFF, 0x6E, 0x6E, 1.0)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 54),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 48),
                      child: Text(
                        '- openup',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 36, fontWeight: FontWeight.w300),
                      ),
                    ),
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
