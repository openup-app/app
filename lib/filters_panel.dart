import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';

class Filters extends StatefulWidget {
  const Filters({super.key});

  @override
  State<Filters> createState() => _FiltersState();
}

class _FiltersState extends State<Filters> {
  bool _nonBinary = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0xF1, 0xF4, 0xF6, 1.0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const _Title(),
              const SizedBox(height: 20),
              const _Heading(label: 'I\'m interested in seeing...'),
              _Filter(
                label: 'Men',
                checked: false,
                onTapped: () {},
              ),
              _Filter(
                label: 'Women',
                checked: false,
                onTapped: () {},
              ),
              _Filter(
                label: 'Non-Binary',
                checked: _nonBinary,
                onTapped: () => setState(() => _nonBinary = !_nonBinary),
              ),
              const SizedBox(height: 20),
              const _Heading(
                  label: 'I\'m interested in seeing these ethnicities...'),
              _SearchBox(),
              _ShowListButton(
                onPressed: () {},
              ),
              const _Heading(label: 'I\'m interested in people who speak...'),
              _SearchBox(),
              _ShowListButton(
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Button(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'cancel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 19,
                  color: const Color.fromRGBO(0x59, 0x59, 0x72, 1.0)),
            ),
          ),
          onPressed: () {},
        ),
        Expanded(
          flex: 2,
          child: Text(
            'Filters',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 28,
                color: const Color.fromRGBO(0x55, 0x55, 0x55, 1.0)),
          ),
        ),
        Button(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'apply',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontSize: 19,
                  color: const Color.fromRGBO(0x59, 0x59, 0x72, 1.0)),
            ),
          ),
          onPressed: () {},
        ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String label;
  const _Heading({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 16, color: const Color.fromRGBO(0xFF, 0x72, 0x72, 1.0)),
      ),
    );
  }
}

class _ShowListButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ShowListButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Button(
        onPressed: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 5,
            bottom: 10,
            right: 16,
          ),
          child: Text(
            'show list',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                fontSize: 16,
                color: const Color.fromRGBO(0x59, 0x59, 0x72, 1.0)),
          ),
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final bool checked;
  final VoidCallback onTapped;

  const _Filter({
    super.key,
    required this.label,
    required this.checked,
    required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return _Border(
      child: Button(
        onPressed: onTapped,
        child: Padding(
          padding: const EdgeInsets.only(left: 25, right: 19),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: const Color.fromRGBO(0x59, 0x59, 0x59, 1.0),
                        fontSize: 19,
                      ),
                ),
              ),
              if (checked)
                const Icon(
                  Icons.done,
                  color: Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBox extends StatefulWidget {
  const _SearchBox({super.key});

  @override
  State<_SearchBox> createState() => __SearchBoxState();
}

class __SearchBoxState extends State<_SearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Border(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: TextFormField(
            controller: _controller,
            decoration: InputDecoration.collapsed(
              hintText: 'Search',
              hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 19,
                    color: const Color.fromRGBO(0xAB, 0xAB, 0xAB, 1.0),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Border extends StatelessWidget {
  final Widget child;
  const _Border({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            spreadRadius: 0,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.05),
          )
        ],
      ),
      child: child,
    );
  }
}
