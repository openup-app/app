import 'package:flutter/material.dart';

class TitleAndTagline extends StatelessWidget {
  const TitleAndTagline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'title_and_tagline',
      child: DefaultTextStyle(
        style: Theme.of(context).textTheme.bodyMedium!,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'bff',
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(
              height: 6,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                    ),
                children: [
                  const TextSpan(text: 'The only app dedicated to\nmaking '),
                  TextSpan(
                      text: 'new friends',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(fontSize: 24)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
