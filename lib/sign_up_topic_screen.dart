import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/widgets/common.dart';

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
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 36,
                      ),
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
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
            ),
            const SizedBox(height: 4),
            OvalButton(
              onPressed: (_topic == null || _uploading) ? null : _submit,
              child: _uploading
                  ? const LoadingIndicator(color: Colors.black)
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
      (r) {
        GetIt.instance.get<Mixpanel>().track("sign_up_submit_topic");
        context.pushNamed('onboarding-photos');
      },
    );

    setState(() => _uploading = false);
  }
}
