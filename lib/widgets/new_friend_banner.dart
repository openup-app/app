import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/image_builder.dart';
import 'package:openup/widgets/theming.dart';

class NewFriendBanner extends StatelessWidget {
  final String uid;
  final String name;
  final String photo;
  final String chatroomId;

  const NewFriendBanner({
    Key? key,
    required this.uid,
    required this.name,
    required this.photo,
    required this.chatroomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        height: 192,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(
            Radius.circular(30),
          ),
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(0xDE, 0x5D, 0x25, 1.0),
              Color.fromRGBO(0xB8, 0x1A, 0x1A, 1.0),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You\'ve got a new friend',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 18, fontWeight: FontWeight.w300),
                        ),
                        const SizedBox(height: 16),
                        AutoSizeText(
                          name,
                          maxLines: 1,
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 32, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(13),
                      ),
                    ),
                    child: Image.network(
                      photo,
                      width: 86,
                      height: 108,
                      fit: BoxFit.cover,
                      frameBuilder: fadeInFrameBuilder,
                      loadingBuilder: loadingBuilder,
                      errorBuilder: iconErrorBuilder,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'tap to view profile',
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 18, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}
