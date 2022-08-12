import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class FriendshipsPage extends StatelessWidget {
  const FriendshipsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Text(
            'Growing Friendships',
            style: Theming.of(context).text.body,
          ),
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 24.0),
                child: Text('Search'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              text: TextSpan(
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                children: [
                  const TextSpan(text: 'To maintain '),
                  TextSpan(
                    text: 'friendships ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'on openup, you must talk to '),
                  TextSpan(
                    text: 'each other ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(
                      text:
                          'once every 72 hours. Not doing so will result in your friendship '),
                  TextSpan(
                    text: 'falling apart (deleted)',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromRGBO(0xFF, 0x0, 0x0, 1.0),
                        ),
                  ),
                  const TextSpan(text: '. This app is for people who are '),
                  TextSpan(
                    text: 'serious ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'about making '),
                  TextSpan(
                    text: 'friends',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 40,
              separatorBuilder: (context, _) {
                return Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 99),
                  color: const Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
                );
              },
              itemBuilder: (context, index) {
                return Button(
                  onPressed: () {},
                  child: SizedBox(
                    height: 86,
                    child: Row(
                      children: [
                        if (index.isOdd)
                          SizedBox(
                            width: 42,
                            child: Center(
                              child: Text(
                                'new',
                                style: Theming.of(context)
                                    .text
                                    .body
                                    .copyWith(fontWeight: FontWeight.w300),
                              ),
                            ),
                          ),
                        if (index.isEven)
                          SizedBox(
                            width: 42,
                            child: index == 0
                                ? const SizedBox.shrink()
                                : Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(
                                            0x00, 0x85, 0xFF, 1.0),
                                      ),
                                    ),
                                  ),
                          ),
                        Stack(
                          children: [
                            Container(
                              width: 65,
                              height: 65,
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                  'https://picsum.photos/id/200/200/'),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SabrinaFalls',
                                style: Theming.of(context).text.body,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fort Worth, Texas',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '40:00:00',
                                    style: Theming.of(context)
                                        .text
                                        .body
                                        .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lonely',
                                    style: Theming.of(context)
                                        .text
                                        .body
                                        .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w300),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
