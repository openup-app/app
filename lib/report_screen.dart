import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/widgets/button.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String uid;
  const ReportScreen({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final _textController = TextEditingController();
  _Reason _reason = _Reason.violentRepulsive;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
      if (_textController.text.isNotEmpty) {
        setState(() => _reason = _Reason.other);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(0xFF, 0x8E, 0x8E, 0.9),
                Color.fromRGBO(0xBD, 0x20, 0x20, 0.74),
              ],
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              unselectedWidgetColor: Colors.white,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 27, vertical: 72),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(29)),
                      color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.5),
                      boxShadow: [
                        BoxShadow(
                          blurStyle: BlurStyle.normal,
                          blurRadius: 10,
                          offset: Offset(0.0, 4.0),
                          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
                        ),
                      ],
                    ),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 362),
                      child: ListView(
                        children: [
                          const SizedBox(height: 42),
                          Center(
                            child: Text(
                              'Reporting User',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 32),
                          RadioListTile<_Reason>(
                            title: Text(
                              'Violent or repulsive',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            activeColor: Colors.white,
                            value: _Reason.violentRepulsive,
                            groupValue: _reason,
                            onChanged: _onRadioChanged,
                          ),
                          RadioListTile<_Reason>(
                            title: Text(
                              'Harassment or bullying',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            activeColor: Colors.white,
                            value: _Reason.harassmentBullying,
                            groupValue: _reason,
                            onChanged: _onRadioChanged,
                          ),
                          RadioListTile<_Reason>(
                            title: Text(
                              'Child in call',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            activeColor: Colors.white,
                            value: _Reason.child,
                            groupValue: _reason,
                            onChanged: _onRadioChanged,
                          ),
                          RadioListTile<_Reason>(
                            title: Text(
                              'Other',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                            ),
                            activeColor: Colors.white,
                            value: _Reason.other,
                            groupValue: _reason,
                            onChanged: _onRadioChanged,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 200,
                            child: TextFormField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Explain what happened',
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 31.0),
                              child: SizedBox(
                                width: 162,
                                height: 43,
                                child: GradientButton(
                                  onPressed: _uploading ? null : _upload,
                                  child: const Text('send'),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).padding.left + 32,
                  top: MediaQuery.of(context).padding.top + 8,
                  child: Button(
                    onPressed: Navigator.of(context).pop,
                    child: const Padding(
                        padding: EdgeInsets.all(8), child: Icon(Icons.close)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onRadioChanged(_Reason? value) {
    if (value != null) {
      setState(() {
        _reason = value;
      });
    }
  }

  void _upload() async {
    final userState = ref.read(userProvider);
    final uid = userState.map(
      guest: (guest) => null,
      signedIn: (signedIn) => signedIn.account.profile.uid,
    );
    if (uid == null) {
      return Future.value();
    }
    setState(() => _uploading = true);

    final api = ref.read(apiProvider);
    final extraText = _textController.text;
    final extra = _reason == _Reason.other
        ? (extraText.isEmpty ? null : extraText)
        : null;
    final result = await api.reportUser(
      uid: uid,
      reportedUid: widget.uid,
      reason: _reason.name,
      extra: extra,
    );

    if (!mounted) {
      return;
    }

    setState(() => _uploading = false);

    result.fold(
      (l) => displayError(context, l),
      (r) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully reported user'),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }
}

enum _Reason { violentRepulsive, harassmentBullying, child, other }

class ReportScreenArguments {
  final String uid;

  ReportScreenArguments({
    required this.uid,
  });
}
