import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_form.dart';
import 'package:openup/widgets/theming.dart';

class SignUpAttributesScreen extends ConsumerStatefulWidget {
  const SignUpAttributesScreen({Key? key}) : super(key: key);

  @override
  _SignUpAttributesScreenState createState() => _SignUpAttributesScreenState();
}

class _SignUpAttributesScreenState
    extends ConsumerState<SignUpAttributesScreen> {
  Attributes _attributes = const Attributes(
    gender: Gender.male,
    skinColor: SkinColor.light,
    weight: 200,
    height: 60,
    ethnicity: 'White',
  );

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top + 32,
          ),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Introduce yourself',
              style: Theming.of(context).text.body.copyWith(
                    color: const Color.fromRGBO(0x62, 0xCD, 0xE3, 1.0),
                    fontWeight: FontWeight.w400,
                    fontSize: 30,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Fill out the following information so others can find the real you',
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
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: AttributesForm(
                        attributes: _attributes,
                        onChanged: (attributes) {
                          setState(() => _attributes = attributes);
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
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SignificantButton.pink(
                onPressed: () async {
                  setState(() => _uploading = true);
                  final user = FirebaseAuth.instance.currentUser;
                  final uid = user?.uid;
                  if (uid != null) {
                    final usersApi = ref.read(usersApiProvider);
                    await usersApi.updateAttributes(uid, _attributes);
                    if (mounted) {
                      setState(() => _uploading = false);
                      Navigator.of(context).pushNamed('sign-up-photos');
                    }
                  }
                },
                child: _uploading
                    ? const CircularProgressIndicator()
                    : const Text('Continue'),
              ),
              const MaleFemaleConnectionImageApart(),
            ],
          ),
        ],
      ),
    );
  }
}
