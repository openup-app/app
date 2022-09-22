import 'package:flutter/material.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/icon_with_shadow.dart';

class ShareButton extends StatelessWidget {
  final Profile profile;
  const ShareButton({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile sharing coming soon'),
          ),
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: IconWithShadow(
          Icons.reply,
          color: Colors.white,
          size: 32,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}
