import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/gallery.dart';
import 'package:openup/widgets/icon_with_shadow.dart';
import 'package:share_plus/share_plus.dart';

class ShareButton extends StatelessWidget {
  final Profile profile;
  const ShareButton({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _SharePage(profile: profile),
        );
      },
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: IconWithShadow(
          Icons.reply,
          color: Colors.white,
          size: 32,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }
}

class _SharePage extends ConsumerStatefulWidget {
  final Profile profile;
  const _SharePage({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  ConsumerState<_SharePage> createState() => _SharePageState();
}

class _SharePageState extends ConsumerState<_SharePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = 'openupfriends.com/discover/${widget.profile.uid}';
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(39),
          topRight: Radius.circular(39),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 26),
          SizedBox(
            height: 58,
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.profile.name,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                ),
                Positioned(
                  right: 39,
                  top: 0,
                  child: Button(
                    onPressed: Navigator.of(context).pop,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                child: CinematicGallery(
                  slideshow: true,
                  gallery: widget.profile.collection.photos,
                ),
              ),
            ),
          ),
          const SizedBox(height: 31),
          Text(
            'Share profile',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                ),
          ),
          const SizedBox(height: 13),
          Button(
            onPressed: () {
              ref.read(mixpanelProvider).track("share_profile");
              Share.share(
                url,
                subject: 'The only app dedicated to making new friends',
              );
            },
            child: Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Icon(
                      Icons.share,
                      color: Color.fromRGBO(0x36, 0x36, 0x36, 1.0),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: AutoSizeText(
                        url,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        minFontSize: 9,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.black,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
