import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/keyboard_screen.dart';
import 'package:openup/widgets/theming.dart';

class SignUpTopicScreen extends ConsumerStatefulWidget {
  const SignUpTopicScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpTopicScreen> createState() => _SignUpTopicScreenState();
}

class _SignUpTopicScreenState extends ConsumerState<SignUpTopicScreen> {
  final _nameController = TextEditingController();
  bool _uploading = false;
  Topic? _topic;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Colors.black),
        child: KeyboardScreen(
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Everyone is here to make friends, which one reason fits you the most?',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w300, fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Wrap(
                  alignment: WrapAlignment.start,
                  spacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final topic in Topic.values)
                      Chip(
                        label: topicLabel(topic),
                        selected: _topic == topic,
                        onSelected: () => setState(() => _topic = topic),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(35.0),
                  child: Button(
                    onPressed: (_topic == null || _uploading) ? null : _submit,
                    child: OutlinedArea(
                      child: Center(
                        child: _uploading
                            ? const CircularProgressIndicator()
                            : const Text('continue'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() async {
    final topic = _topic;
    if (topic == null) {
      return;
    }

    setState(() => _uploading = true);

    final result = await updateTopic(
      context: context,
      ref: ref,
      topic: topic,
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) => Navigator.of(context).pushReplacementNamed('sign-up-photos'),
    );

    setState(() => _uploading = false);
  }
}
