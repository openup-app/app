import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class SignUpOverviewPage extends StatefulWidget {
  const SignUpOverviewPage({Key? key}) : super(key: key);

  @override
  State<SignUpOverviewPage> createState() => _SignUpOverviewPageState();
}

class _SignUpOverviewPageState extends State<SignUpOverviewPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final newPage = _controller.page?.round() ?? _page;
      if (_page != newPage) {
        setState(() => _page = newPage);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  children: const [
                    _Page1(),
                    _Page2(),
                    _Page3(),
                    _Page4(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 39.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _page == i ? Colors.white : Colors.grey,
                        ),
                      )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Button(
                  onPressed: () {
                    if (_page < 3) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    } else {
                      Navigator.of(context)
                          .pushReplacementNamed('sign-up-name');
                    }
                  },
                  child: Container(
                    height: 51,
                    margin: const EdgeInsets.only(left: 16, right: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(40),
                      ),
                    ),
                    child: Center(
                      child: _page == 3
                          ? const Text('Let\'s get started')
                          : const Text('continue'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Page1 extends StatelessWidget {
  const _Page1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Discover people who also want to make new friends',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(fontSize: 30),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/onboard_discover.jpg',
            ),
          ),
        ],
      ),
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Goodbye texting, voice messages only',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(fontSize: 30),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/onboard_chat.jpg',
            ),
          ),
        ],
      ),
    );
  }
}

class _Page3 extends StatelessWidget {
  const _Page3({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Keep up with your new friends, lose them if you don\'t',
            textAlign: TextAlign.center,
            style: Theming.of(context).text.body.copyWith(fontSize: 30),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/onboard_countdown.jpg',
            ),
          ),
        ],
      ),
    );
  }
}

class _Page4 extends StatelessWidget {
  const _Page4({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'The Keys to making Successful Friendship',
          textAlign: TextAlign.center,
          style: Theming.of(context).text.body.copyWith(fontSize: 30),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              children: [
                SizedBox(
                  width: 290,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. \n\n\n2. \n\n\n\n3. \n\n\n\n4. \n\n\n\n\n5. ',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.8),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: Theming.of(context).text.body.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w300,
                                  height: 1.8,
                                ),
                            children: [
                              TextSpan(
                                text: 'Give it time. ',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.8),
                              ),
                              const TextSpan(
                                  text:
                                      'If you don’t water your plants, they die. Same goes for your friendships, be persistent but patient.\n'),
                              TextSpan(
                                text: 'Pay Attention. ',
                                style: Theming.of(context).text.body.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.8,
                                    ),
                              ),
                              const TextSpan(
                                  text:
                                      'People notice when you remember things about them, act on those oppurtunities to show how you care.\n'),
                              TextSpan(
                                text: 'Don’t be a one-sided friend. ',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.8),
                              ),
                              const TextSpan(
                                  text:
                                      'If you have someone who is constantly you up about hanging or talking, follow up with them and be sure to reply!\n'),
                              TextSpan(
                                text: 'Let your guard down. ',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.8),
                              ),
                              const TextSpan(
                                  text:
                                      'A lot of the doubts and fears you have are in your mind, don’t let your mind get in the way of risk and ruin oppurtunities for you.\n'),
                              TextSpan(
                                text: 'Lighten up. ',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.8),
                              ),
                              const TextSpan(
                                  text:
                                      'Don’t take things so seriously. Expectations, assumptions, and illogical conclusions can destroy any relationship, have fun and be open.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
