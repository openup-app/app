import 'package:flutter/material.dart';

/// A modal which can only be dismissed by invoking the returned
/// callback.
VoidCallback showBlockingModalDialog({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  BuildContext? dialogContext;
  showDialog(
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
class Loading extends StatelessWidget {
  final Widget? title;
  final Widget? label;

  const Loading({
    Key? key,
    this.title,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      backgroundColor: Colors.black,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          if (label != null) const SizedBox(height: 20),
          if (label != null) label!,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
