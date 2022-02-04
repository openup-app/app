import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/male_female_connection_image.dart';
import 'package:openup/widgets/profile_form.dart';
import 'package:openup/widgets/theming.dart';

class PrivateProfileScreen extends ConsumerStatefulWidget {
  final PrivateProfile initialProfile;

  const PrivateProfileScreen({
    Key? key,
    required this.initialProfile,
  }) : super(key: key);

  @override
  _PrivateProfileScreenState createState() => _PrivateProfileScreenState();
}

class _PrivateProfileScreenState extends ConsumerState<PrivateProfileScreen> {
  late PrivateProfile _profile;

  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: PrivateProfileForm(
                      profile: _profile,
                      onChanged: (profile) {
                        setState(() => _profile = profile);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SignificantButton.pink(
              onPressed: () async {
                setState(() => _uploading = true);
                final user = FirebaseAuth.instance.currentUser;
                final uid = user?.uid;
                if (uid != null) {
                  final usersApi = ref.read(usersApiProvider);
                  await usersApi.updatePrivateProfile(uid, _profile);
                  if (mounted) {
                    setState(() => _uploading = false);
                    Navigator.of(context).pop();
                  }
                }
              },
              child: _uploading
                  ? const CircularProgressIndicator()
                  : const Text('Complete'),
            ),
            const MaleFemaleConnectionImageApart(),
          ],
        ),
      ],
    );
  }
}
