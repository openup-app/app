import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/profile_button.dart';
import 'package:openup/widgets/theming.dart';

class LobbyListPage extends StatefulWidget {
  const LobbyListPage({Key? key}) : super(key: key);

  @override
  State<LobbyListPage> createState() => _LobbyListPageState();
}

class _LobbyListPageState extends State<LobbyListPage> {
  final _topics = [
    'Just moved',
    'Going out',
    'Lonely',
    'On vacation',
    'Business',
  ];
  int? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding:
                  EdgeInsets.only(top: MediaQuery.of(context).padding.top + 88),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 27.0, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'People available to talk ...',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color:
                                  const Color.fromRGBO(0x8E, 0x8E, 0x8E, 1.0)),
                        ),
                        const Spacer(),
                        Text(
                          '25,120',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color:
                                  const Color.fromRGBO(0x00, 0xD1, 0xFF, 1.0)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return _OnlineUserTile(
                          onPressed: () {},
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).padding.top + 16,
            child: _TopicSelector(
              topics: _topics,
              selected: _selectedTopic,
              onSelected: (index) => setState(() => _selectedTopic = index),
            ),
          ),
          Positioned(
            right: 24,
            top: MediaQuery.of(context).padding.top + 16,
            child: const ProfileButton(
              color: Color.fromRGBO(0x89, 0xDE, 0xFF, 1.0),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 18.0, bottom: 12),
                  child: Button(
                    onPressed: () {},
                    child: Container(
                      width: 140,
                      height: 61,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(61)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color.fromRGBO(0x26, 0xEF, 0x3A, 1.0),
                            Color.fromRGBO(0x0A, 0x98, 0x18, 1.0),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            offset: Offset(0.0, 4.0),
                            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.call,
                            size: 30,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Random',
                            style: Theming.of(context).text.body.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: const BoxDecoration(color: Colors.white),
                  child: Container(
                    height: 54,
                    margin: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    padding: const EdgeInsets.only(left: 38, right: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(34.5),
                      ),
                      color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration.collapsed(
                              hintText: 'Why are you here today?',
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_filled,
                          color: Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '59:08',
                          style: Theming.of(context).text.body.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              color:
                                  const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
                        ),
                      ],
                    ),
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

class _OnlineUserTile extends StatelessWidget {
  final VoidCallback onPressed;
  const _OnlineUserTile({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0x01, 0xCB, 0xF7, 1.0),
        borderRadius: BorderRadius.all(Radius.circular(38)),
      ),
      child: Button(
        onPressed: () {},
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(top: 20.0, left: 27.0, right: 27.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AutoSizeText(
                              'Name',
                              minFontSize: 16,
                              maxFontSize: 36,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theming.of(context).text.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: [
                                  const Shadow(
                                    blurRadius: 7.0,
                                    offset: Offset(2.0, 2.0),
                                    color:
                                        Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _buildSymbolText(context, Icons.people, 'Chinese'),
                        _buildSymbolText(context, Icons.sick, 'Agnostic'),
                        _buildSymbolText(context, Icons.work, 'Film/Video'),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(13)),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 4.0,
                          offset: Offset(0.0, 4.0),
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                    child: Image.network(
                      'https://picsum.photos/200/300',
                      height: 124,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color.fromRGBO(0x08, 0x6A, 0x7F, 1.0),
                    Color.fromRGBO(0x05, 0x57, 0x69, 1.0),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'I\'m at Varsity, drinks tonight anyone?',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theming.of(context).text.body.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolText(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(width: 11),
          Text(
            text,
            style: Theming.of(context).text.body.copyWith(
                fontSize: 16, color: Colors.white, fontWeight: FontWeight.w300),
          ),
        ],
      ),
    );
  }
}

class _TopicSelector extends StatefulWidget {
  final List<String> topics;
  final int? selected;
  final void Function(int? index) onSelected;

  const _TopicSelector({
    Key? key,
    required this.topics,
    required this.selected,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_TopicSelector> createState() => __TopicSelectorState();
}

class __TopicSelectorState extends State<_TopicSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 75),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0xE6, 0xE6, 0xE6, 1.0),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Button(
            onPressed: () {
              setState(() => _open = !_open);
              if (_open) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
            child: Container(
              height: 60,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 40, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _open
                            ? 'Pick a topic to discuss'
                            : (widget.selected == null
                                ? 'Pick a topic to discuss'
                                : widget.topics[widget.selected!]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theming.of(context).text.body.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            color: const Color.fromRGBO(0x7B, 0x7B, 0x7B, 1.0)),
                      ),
                    ),
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 0.25).animate(_controller),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 40,
                        color: Color.fromRGBO(0xA2, 0xA2, 0xA2, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _controller,
            child: FadeTransition(
              opacity: _controller,
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: widget.topics.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 57,
                    margin: const EdgeInsets.only(top: 4, bottom: 4, right: 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Button(
                      onPressed: () {
                        setState(() => _open = false);
                        widget.onSelected(index);
                        _controller.reverse();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 40.0, right: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.topics[index],
                                style: Theming.of(context).text.body.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                    color: const Color.fromRGBO(
                                        0xA2, 0xA2, 0xA2, 1.0)),
                              ),
                            ),
                            if (widget.selected == index)
                              Container(
                                width: 35,
                                height: 35,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color.fromRGBO(0x00, 0x93, 0x4C, 1.0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.done, size: 32),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
