import 'package:flutter/material.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/restart_app.dart';

class SignupRules extends StatefulWidget {
  const SignupRules({super.key});

  @override
  State<SignupRules> createState() => _SignupRulesState();
}

class _SignupRulesState extends State<SignupRules> {
  bool _ticked1 = false;
  bool _ticked2 = false;
  bool _ticked3 = false;
  bool _ticked4 = false;
  bool _ticked5 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'Covered By Your Grace',
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          child: Builder(
            builder: (context) {
              return Center(
                child: SizedBox(
                  width: 307,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Plus One Rules',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 55,
                        ),
                      ),
                      _Row(
                        label: const Text('You are here to meet new people'),
                        ticked: _ticked1,
                        onChanged: (value) => setState(() => _ticked1 = value),
                      ),
                      _Row(
                        label: const Text(
                            'You will get out of your comfort zone and message new people'),
                        ticked: _ticked2,
                        onChanged: (value) => setState(() => _ticked2 = value),
                      ),
                      _Row(
                        label: const Text(
                            'You can only use your voice, no texting'),
                        ticked: _ticked3,
                        onChanged: (value) => setState(() => _ticked3 = value),
                      ),
                      _Row(
                        label:
                            const Text('Turn up your volume to hear profiles'),
                        ticked: _ticked4,
                        onChanged: (value) => setState(() => _ticked4 = value),
                      ),
                      _Row(
                        label: const Text(
                            'Keep your notifications on, people will message you'),
                        ticked: _ticked5,
                        onChanged: (value) => setState(() => _ticked5 = value),
                      ),
                      Button(
                        onPressed: !(_ticked1 &&
                                _ticked2 &&
                                _ticked3 &&
                                _ticked4 &&
                                _ticked5)
                            ? null
                            : () => RestartApp.restartApp(context),
                        child: Container(
                          width: 279,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.all(
                              Radius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Meet new people',
                            style: TextStyle(color: Colors.white, fontSize: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final Text label;
  final bool ticked;
  final ValueChanged<bool> onChanged;

  const _Row({
    super.key,
    required this.label,
    required this.ticked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => onChanged(!ticked),
      child: Row(
        children: [
          Container(
            width: 21,
            height: 21,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(width: 2),
            ),
            child: ticked
                ? const Icon(
                    Icons.done,
                    color: Colors.black,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: label,
          ),
        ],
      ),
    );
  }
}
