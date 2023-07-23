import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/loading_dialog.dart';

void displayError(BuildContext context, ApiError error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(errorToMessage(error)),
    ),
  );
}

String errorToMessage(ApiError error) {
  return error.map(
    network: (_) => 'Unable to connect to server',
    client: (client) {
      return client.error.map(
        badRequest: (_) => 'Failed to perform action',
        unauthorized: (_) => 'You are not logged in',
        notFound: (_) => 'Not found',
        forbidden: (_) => 'Something went wrong, access denied',
        conflict: (_) => 'Busy, try again',
      );
    },
    server: (_) => 'Something went wrong on our end, please try again',
  );
}

Future<T> withBlockingModal<T>({
  required BuildContext context,
  required String label,
  required Future<T> future,
}) async {
  final popDialog = showBlockingModalDialog(
    context: context,
    builder: (context) {
      return LoadingDialog(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.white,
          ),
        ),
      );
    },
  );

  final result = await future;
  popDialog();
  return result;
}
