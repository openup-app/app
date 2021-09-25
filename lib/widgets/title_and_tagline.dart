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
            Image.asset(
              'assets/images/title.png',
              height: 80,
              fit: BoxFit.fitHeight,
            ),
            const SizedBox(
              height: 6,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Theming.of(context).shadow.withOpacity(0.2),
                    offset: const Offset(0.0, 4.0),
                    blurRadius: 4.0,
                  ),
                ],
                color: Theming.of(context).datingRed2,
              ),
              child: Text(
                'a new way to meet people',
                style: Theming.of(context).text.body.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
