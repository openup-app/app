import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/profile_audio_recorder.dart';
import 'package:openup/widgets/theming.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({Key? key}) : super(key: key);

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _pageController = PageController(initialPage: 10000);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            itemBuilder: (context, index) {
              final i = index % 4;
              return Image.network(
                'https://picsum.photos/20$i/20$i',
                fit: BoxFit.cover,
              );
            },
          ),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          top: MediaQuery.of(context).padding.top + 16,
          child: Button(
            onPressed: () =>
                Navigator.of(context).pushNamed('public-profile-edit'),
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(40)),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Edit Photos',
                    style: Theming.of(context).text.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          height: 72,
          child: ProfileAudioRecorder(),
        ),
        Positioned(
          left: MediaQuery.of(context).padding.left + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: const BackButton(),
        ),
        Positioned(
          right: MediaQuery.of(context).padding.right + 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          child: const HomeButton(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
