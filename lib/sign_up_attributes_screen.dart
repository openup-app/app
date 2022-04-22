import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_form.dart';
import 'package:openup/widgets/theming.dart';

class SignUpAttributesScreen extends ConsumerStatefulWidget {
  const SignUpAttributesScreen({Key? key}) : super(key: key);

  @override
  _SignUpAttributesScreenState createState() => _SignUpAttributesScreenState();
}

class _SignUpAttributesScreenState
    extends ConsumerState<SignUpAttributesScreen> {
  Interests _interests = const Interests(interests: []);

  bool _uploading = false;
  int? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_expandedSection != null) {
          setState(() => _expandedSection = null);
        }
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top + 32,
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: BackIconButton(
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Introduce yourself',
                    style: Theming.of(context).text.body.copyWith(
                          color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                          fontWeight: FontWeight.w400,
                          fontSize: 30,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'This information is only seen by you',
                  textAlign: TextAlign.center,
                  style: Theming.of(context).text.body.copyWith(
                        color: const Color.fromRGBO(0x99, 0x99, 0x99, 1.0),
                        fontWeight: FontWeight.w400,
                        fontSize: 18,
                      ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: AttributesForm(
                            interests: _interests,
                            onChanged: (attributes) {
                              setState(() => _interests = attributes);
                            },
                            expandedSection: _expandedSection,
                            onExpansion: (index) =>
                                setState(() => _expandedSection = index),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Button(
              onPressed: _submit,
              child: Container(
                height: 100,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromRGBO(0xFF, 0xA1, 0xA1, 1.0),
                      Color.fromRGBO(0xFF, 0xCC, 0xCC, 1.0),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: _uploading
                    ? const CircularProgressIndicator()
                    : const Text('Continue'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    setState(() => _uploading = true);

    final userState = ref.read(userProvider);
    final api = GetIt.instance.get<Api>();

    final interests = _interests;
    final result = await api.updateInterests(userState.uid, interests);

    if (!mounted) {
      return;
    }

    result.fold(
      (l) => displayError(context, l),
      (r) {
        ref.read(userProvider.notifier).interests(interests);
        Navigator.of(context).pushNamed('sign-up-photos');
      },
    );

    setState(() => _uploading = false);
  }
}
