import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/gradient_mask.dart';
import 'package:openup/widgets/scaffold.dart';

class SignupGlamourName extends ConsumerStatefulWidget {
  const SignupGlamourName({super.key});

  @override
  ConsumerState<SignupGlamourName> createState() => _SignupGlamourNameState();
}

class _SignupGlamourNameState extends ConsumerState<SignupGlamourName> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(accountCreationParamsProvider).name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: OpenupAppBar(
        blurBackground: false,
        body: OpenupAppBarBody(
          trailingPadding: EdgeInsets.zero,
          trailing: OpenupAppBarTextButton(
            onPressed: !_canSubmit(ref.watch(accountCreationParamsProvider))
                ? null
                : _submit,
            label: 'next',
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 89,
            left: 0,
            right: 0,
            child: const GradientMask(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 29),
                child: AutoSizeText(
                  'What\'s your\nname?',
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 29,
            bottom: 32 + MediaQuery.of(context).viewInsets.bottom,
            left: 29,
            child: GradientMask(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                ],
              ),
              child: TextFormField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.end,
                onChanged:
                    ref.read(accountCreationParamsProvider.notifier).name,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Name',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSubmit(AccountCreationParams params) => params.nameValid;

  void _submit() {
    if (!_canSubmit(ref.read(accountCreationParamsProvider))) {
      return;
    }
    final analytics = ref.read(analyticsProvider);
    analytics.trackSignupSubmitName();
    context.pushNamed('signup_age');
  }
}
