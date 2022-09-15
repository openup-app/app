import 'package:flutter/widgets.dart';
import 'package:openup/widgets/theming.dart';

class TitleAndTagline extends StatelessWidget {
  const TitleAndTagline({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'title_and_tagline',
      child: DefaultTextStyle(
        style: Theming.of(context).text.body,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'openup',
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 80, fontWeight: FontWeight.w700),
            ),
            const SizedBox(
              height: 6,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
                children: [
                  const TextSpan(text: 'The only app dedicated to\nmaking '),
                  TextSpan(
                      text: 'new friends',
                      style: Theming.of(context)
                          .text
                          .body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
