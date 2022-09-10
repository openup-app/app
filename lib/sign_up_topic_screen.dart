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
    return Scaffold(
      backgroundColor: Colors.black,
      // Makes column fill screen
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 70),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 356),
                child: Text(
                  'Everyone is here to make friends, which one reason fits you the most?',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 36),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 0,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final topic in Topic.values)
                    Chip(
                      label: topicLabel(topic),
                      height: 46,
                      selected: _topic == topic,
                      onSelected: () => setState(() => _topic = topic),
                    ),
                ],
              ),
            ),
            OvalButton(
              onPressed: (_topic == null || _uploading) ? null : _submit,
              child: _uploading
                  ? const CircularProgressIndicator()
                  : const Text('continue'),
            ),
            const SizedBox(height: 59),
          ],
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
      (r) => Navigator.of(context).pushNamed('sign-up-photos'),
    );

    setState(() => _uploading = false);
  }
}
