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
                  .copyWith(fontSize: 64, fontWeight: FontWeight.w300),
            ),
            const SizedBox(
              height: 6,
            ),
            Text(
              'a new way to meet people',
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
            ),
          ],
        ),
      ),
    );
  }
}
