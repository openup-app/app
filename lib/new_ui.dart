import 'dart:math';
import 'dart:ui';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/theming.dart';

class NewHome extends StatefulWidget {
  const NewHome({Key? key}) : super(key: key);

  @override
  State<NewHome> createState() => _NewHomeState();
}

class _NewHomeState extends State<NewHome> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: 0,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      home: Theming(
        child: Builder(
          builder: (context) {
            return Scaffold(
              backgroundColor: Colors.black,
              extendBody: true,
              bottomNavigationBar: SizedBox(
                height: 72,
                child: _BlurredSurface(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Button(
                        child: Text(
                          'Discover',
                          style: Theming.of(context).text.body.copyWith(
                              fontWeight: _tabController.index != 0
                                  ? FontWeight.w300
                                  : null),
                        ),
                        onPressed: () {
                          _tabController.index = 0;
                          setState(() {});
                        },
                      ),
                      Button(
                        child: Text(
                          'Friendships',
                          style: Theming.of(context).text.body.copyWith(
                              fontWeight: _tabController.index != 1
                                  ? FontWeight.w300
                                  : null),
                        ),
                        onPressed: () {
                          _tabController.index = 1;
                          setState(() {});
                        },
                      ),
                      Button(
                        child: Text(
                          'Profile',
                          style: Theming.of(context).text.body.copyWith(
                              fontWeight: _tabController.index != 2
                                  ? FontWeight.w300
                                  : null),
                        ),
                        onPressed: () {
                          _tabController.index = 2;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _DiscoverPage(),
                  _FriendshipsPage(),
                  _ProfilePage(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscoverPage extends StatelessWidget {
  const _DiscoverPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const obscuredTop = 164.0;
        const obscuredBottom = 72.0;
        const bottomHeight = 135.0;
        const padding = 32.0;
        final itemExtent =
            constraints.maxHeight - obscuredTop - obscuredBottom + padding;
        return Stack(
          children: [
            Positioned.fill(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: obscuredTop),
                physics: _SnappingScrollPhysics(
                  itemExtent: itemExtent,
                  mainAxisStartPadding: obscuredTop,
                ),
                itemBuilder: (context, index) {
                  return SizedBox(
                    height: itemExtent,
                    // color: Colors.pink,
                    // margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          child: Container(
                            foregroundDecoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black,
                                ],
                                stops: [
                                  0.2,
                                  0.7,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: bottomHeight),
                                  child: Image.network(
                                    'https://picsum.photos/id/690/200/',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 16,
                                  top: 16,
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(height: 24),
                                      Button(
                                        onPressed: () {},
                                        child: const Icon(
                                          Icons.bookmark_outline,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Button(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (context) {
                                              return const Theming(
                                                child: _SharePage(),
                                              );
                                            },
                                          );
                                        },
                                        child: const Icon(
                                          Icons.reply,
                                          color: Colors.white,
                                          size: 32,
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 12 + padding,
                          height: bottomHeight,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SammieJammy $index',
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(fontSize: 24),
                                      ),
                                      Text(
                                        'Fort Worth, Texas',
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w300),
                                      )
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Icon(
                                        Icons.more_horiz,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      Text(
                                        'Can\'t sleep',
                                        style: Theming.of(context)
                                            .text
                                            .body
                                            .copyWith(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w400),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const _RecordButton(
                                  label: 'Invite to voice chat'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 154,
              child: Stack(
                children: [
                  const _BlurredSurface(
                    child: SizedBox.expand(),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Discover new people',
                            style: Theming.of(context).text.body,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 16, fontWeight: FontWeight.w300),
                            children: [
                              TextSpan(
                                  text: 'Discover ',
                                  style: Theming.of(context).text.body.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const TextSpan(
                                  text: 'others who also want to make '),
                              TextSpan(
                                text: 'new friends',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            scrollDirection: Axis.horizontal,
                            children: [
                              _Chip(
                                label: 'All',
                                selected: true,
                                onSelected: () {},
                              ),
                              _Chip(
                                label: 'Lonely',
                                selected: false,
                                onSelected: () {},
                              ),
                              _Chip(
                                label: 'Favourites',
                                selected: false,
                                onSelected: () {},
                              ),
                              _Chip(
                                label: 'Just Moved',
                                selected: false,
                                onSelected: () {},
                              ),
                              _Chip(
                                label: 'Can\'t Sleep',
                                selected: false,
                                onSelected: () {},
                              ),
                              _Chip(
                                label: 'Bored',
                                selected: false,
                                onSelected: () {},
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FriendshipsPage extends StatelessWidget {
  const _FriendshipsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Text(
            'Growing Friendships',
            style: Theming.of(context).text.body,
          ),
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(),
              borderRadius: const BorderRadius.all(Radius.circular(24)),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 24.0),
                child: Text('Search'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              text: TextSpan(
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                children: [
                  const TextSpan(text: 'To maintain '),
                  TextSpan(
                    text: 'friendships ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'on openup, you must talk to '),
                  TextSpan(
                    text: 'each other ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(
                      text:
                          'once every 72 hours. Not doing so will result in your friendship '),
                  TextSpan(
                    text: 'falling apart (deleted)',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color.fromRGBO(0xFF, 0x0, 0x0, 1.0),
                        ),
                  ),
                  const TextSpan(text: '. This app is for people who are '),
                  TextSpan(
                    text: 'serious ',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: 'about making '),
                  TextSpan(
                    text: 'friends',
                    style: Theming.of(context).text.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: 40,
              separatorBuilder: (context, _) {
                return Container(
                  height: 1,
                  margin: const EdgeInsets.only(left: 99),
                  color: const Color.fromRGBO(0x44, 0x44, 0x44, 1.0),
                );
              },
              itemBuilder: (context, index) {
                return Button(
                  onPressed: () {},
                  child: SizedBox(
                    height: 86,
                    child: Row(
                      children: [
                        if (index.isOdd)
                          SizedBox(
                            width: 42,
                            child: Center(
                              child: Text(
                                'new',
                                style: Theming.of(context)
                                    .text
                                    .body
                                    .copyWith(fontWeight: FontWeight.w300),
                              ),
                            ),
                          ),
                        if (index.isEven)
                          SizedBox(
                            width: 42,
                            child: index == 0
                                ? const SizedBox.shrink()
                                : Center(
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color.fromRGBO(
                                            0x00, 0x85, 0xFF, 1.0),
                                      ),
                                    ),
                                  ),
                          ),
                        Stack(
                          children: [
                            Container(
                              width: 65,
                              height: 65,
                              clipBehavior: Clip.hardEdge,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: Image.network(
                                  'https://picsum.photos/id/200/200/'),
                            ),
                            Positioned(
                              right: 2,
                              top: 2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'SabrinaFalls',
                                style: Theming.of(context).text.body,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Fort Worth, Texas',
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 16, fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '40:00:00',
                                    style: Theming.of(context)
                                        .text
                                        .body
                                        .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w400),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lonely',
                                    style: Theming.of(context)
                                        .text
                                        .body
                                        .copyWith(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w300),
                                  ),
                                ],
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: Theming.of(context)
                  .text
                  .body
                  .copyWith(fontWeight: FontWeight.w300),
              children: [
                TextSpan(
                  text: 'openup ',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: 'make new '),
                TextSpan(
                  text: 'friends',
                  style: Theming.of(context)
                      .text
                      .body
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  child: CupertinoSlidingSegmentedControl(
                    children: {
                      'edit': Text(
                        'Edit Profile',
                        style: Theming.of(context).text.body,
                      ),
                      'preview': Text(
                        'Preview',
                        style: Theming.of(context).text.body,
                      ),
                    },
                    onValueChanged: (value) {},
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Button(
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.settings,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'My Pictures',
                    style: Theming.of(context).text.body.copyWith(fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Add your best three pictures',
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 298,
                  margin: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(24)),
                          child: Image.network(
                            'https://picsum.photos/id/691/200/',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(24)),
                                child: Image.network(
                                  'https://picsum.photos/id/691/200/',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(24)),
                                child: Image.network(
                                  'https://picsum.photos/id/691/200/',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 29),
                const Padding(
                  padding: EdgeInsets.only(left: 16, right: 16),
                  child: _RecordButton(label: 'Record new status'),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Reason you\'re here',
                    style: Theming.of(context).text.body.copyWith(fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Choose a category that fits with you',
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _Chip(
                        label: 'Sad',
                        selected: false,
                        onSelected: () {},
                      ),
                      _Chip(
                        label: 'Lonely',
                        selected: false,
                        onSelected: () {},
                      ),
                      _Chip(
                        label: 'Introvert',
                        selected: false,
                        onSelected: () {},
                      ),
                      _Chip(
                        label: 'Talk',
                        selected: true,
                        onSelected: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'My Name',
                    style: Theming.of(context).text.body.copyWith(fontSize: 24),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Text(
                    'Please don\'t use your real name',
                    style: Theming.of(context)
                        .text
                        .body
                        .copyWith(fontSize: 16, fontWeight: FontWeight.w300),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 51,
                  margin: const EdgeInsets.only(left: 16, right: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Text('Heisinghberg',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w300)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharePage extends StatefulWidget {
  const _SharePage({Key? key}) : super(key: key);

  @override
  State<_SharePage> createState() => __SharePageState();
}

class __SharePageState extends State<_SharePage>
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
    const url = 'openupfriends.com/SammieJammy';
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
                  child: Column(
                    children: [
                      Text(
                        'SammieJammy',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                      Text(
                        'Fort Worth, Texas',
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                    ],
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
                child: Image.network(
                  'https://picsum.photos/id/690/200/',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 31),
          Text(
            'Share profile',
            style: Theming.of(context)
                .text
                .body
                .copyWith(fontSize: 24, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 13),
          Button(
            onPressed: () {},
            child: Container(
              height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 32),
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
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: AutoSizeText(
                        url,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        minFontSize: 16,
                        maxFontSize: 20,
                        style: Theming.of(context).text.body.copyWith(
                            fontWeight: FontWeight.w300, color: Colors.black),
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

class _BlurredSurface extends StatelessWidget {
  final Widget child;
  const _BlurredSurface({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const blur = 75.0;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final String label;
  const _RecordButton({
    Key? key,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () {},
      child: Container(
        height: 67,
        decoration: BoxDecoration(
          border:
              Border.all(color: const Color.fromRGBO(0xA9, 0xA9, 0xA9, 1.0)),
          borderRadius: const BorderRadius.all(
            Radius.circular(40),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: Theming.of(context)
                    .text
                    .body
                    .copyWith(fontSize: 20, fontWeight: FontWeight.w300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  const _Chip({
    Key? key,
    required this.label,
    required this.selected,
    this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onSelected,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : const Color.fromRGBO(0x77, 0x77, 0x77, 1.0),
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          border: selected
              ? null
              : Border.all(
                  color: const Color.fromRGBO(0xB9, 0xB9, 0xB9, 1.0),
                ),
        ),
        child: Text(
          label,
          style: Theming.of(context).text.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: selected ? Colors.black : null),
        ),
      ),
    );
  }
}

/// From nxcco and yunyu's SnappingListScrollPhysics: https://gist.github.com/nxcco/98fca4a7dbdecf2f423013cf55230dba
class _SnappingScrollPhysics extends ScrollPhysics {
  final double mainAxisStartPadding;
  final double itemExtent;

  const _SnappingScrollPhysics({
    ScrollPhysics? parent,
    this.mainAxisStartPadding = 0.0,
    required this.itemExtent,
  }) : super(parent: parent);

  @override
  _SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _SnappingScrollPhysics(
      parent: buildParent(ancestor),
      mainAxisStartPadding: mainAxisStartPadding,
      itemExtent: itemExtent,
    );
  }

  double _getItem(ScrollMetrics position) {
    return (position.pixels - mainAxisStartPadding) / itemExtent;
  }

  double _getPixels(ScrollMetrics position, double item) {
    return min(item * itemExtent, position.maxScrollExtent);
  }

  double _getTargetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
    double item = _getItem(position);
    if (velocity < -tolerance.velocity) {
      item -= 0.5;
    } else if (velocity > tolerance.velocity) {
      item += 0.5;
    }
    return _getPixels(position, item.roundToDouble());
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
