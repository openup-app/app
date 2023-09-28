import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/common.dart';

/// A modal which can only be dismissed by invoking the returned
/// callback.
VoidCallback showBlockingModalDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  BuildContext? dialogContext;
  showCupertinoDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      dialogContext = context;
      return WillPopScope(
        onWillPop: () => Future.value(false),
        child: builder(context),
      );
    },
  );
  pop() {
    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }
  }

  return pop;
}

/// A dialog to indicate to the user that work is being done.
class LoadingDialog extends StatelessWidget {
  final Widget? title;
  final Widget? label;

  const LoadingDialog({
    Key? key,
    this.title,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const LoadingIndicator(color: Colors.white),
          if (label != null) ...[
            const SizedBox(height: 20),
            DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: label!,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
