import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:openup/widgets/button.dart';

import 'widgets/party_force_field.dart';

class AfterPartyWaitlist extends StatelessWidget {
  final List<String> videos;

  const AfterPartyWaitlist({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: PartyForceField(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            right: 16,
            child: _NotificationButton(
              onPressed: () {},
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              if (videos.isEmpty) const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Plus\nOne',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Lottie.asset(
                        'assets/images/hangout.json',
                        width: 61,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  'Plus one is an exclusive product made for people who want to connect in a real way.\n\nPlease wait to be invited to the next Plus One event to take your Glamour Shot and gain access. Check out the Glamour shots from our last event.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (videos.isEmpty)
                const Spacer()
              else
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    itemCount: videos.length,
                    itemBuilder: (context, index) {
                      return _Video(
                        url: videos[index],
                      );
                    },
                  ),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Want access sooner? See how you can by tapping the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Button(
                onPressed: () {},
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 49,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Get Quick Access',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ],
      ),
    );
  }
}

class _Video extends StatelessWidget {
  final String url;

  const _Video({
    super.key,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 24,
        ),
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(
            Radius.circular(12),
          ),
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 1),
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
              blurRadius: 13,
            ),
          ],
        ),
        child: const ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(6)),
          child: ColoredBox(color: Colors.brown),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _NotificationButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: SizedBox(
        width: 107,
        height: 36,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(5),
            ),
          ),
          child: Center(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 32,
                    height: 24,
                    child: ClipRect(
                      child: OverflowBox(
                        maxWidth: 160,
                        maxHeight: 160,
                        child: ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Colors.black,
                            BlendMode.srcIn,
                          ),
                          child: Lottie.asset(
                            'assets/images/notification.json',
                            width: 160,
                            height: 160,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(left: 28),
                    child: Text(
                      'Notify me',
                      style: TextStyle(
                        color: Color.fromRGBO(0x4E, 0x4E, 0x4E, 1.0),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
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
}

class AfterPartyWaitlistParams {
  final List<String> sampleVideos;
  const AfterPartyWaitlistParams(this.sampleVideos);
}
