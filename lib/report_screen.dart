import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/users/users_api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/home_button.dart';
import 'package:openup/widgets/theming.dart';

part 'report_screen.freezed.dart';

class ReportScreen extends ConsumerStatefulWidget {
  final String uid;
  const ReportScreen({
    Key? key,
    required this.uid,
  }) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
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
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: ReportScreenTheme.of(context).backgroundGradient,
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 27, vertical: 72),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 42),
                        Center(
                          child: Text(
                            'Reporting User',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 32),
                        RadioListTile<_Reason>(
                          title: Text(
                            'Violent or repulsive',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                          activeColor: Colors.white,
                          value: _Reason.violentRepulsive,
                          groupValue: _reason,
                          onChanged: _onRadioChanged,
                        ),
                        RadioListTile<_Reason>(
                          title: Text(
                            'Harassment or bullying',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                          activeColor: Colors.white,
                          value: _Reason.harassmentBullying,
                          groupValue: _reason,
                          onChanged: _onRadioChanged,
                        ),
                        RadioListTile<_Reason>(
                          title: Text(
                            'Child in call',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                          activeColor: Colors.white,
                          value: _Reason.child,
                          groupValue: _reason,
                          onChanged: _onRadioChanged,
                        ),
                        RadioListTile<_Reason>(
                          title: Text(
                            'Other',
                            style: Theming.of(context).text.body.copyWith(
                                fontSize: 24, fontWeight: FontWeight.w400),
                          ),
                          activeColor: Colors.white,
                          value: _Reason.other,
                          groupValue: _reason,
                          onChanged: _onRadioChanged,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 242),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 23,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(18),
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: TextField(
                                    controller: _textController,
                                    minLines: 10,
                                    maxLines: 10,
                                    decoration: const InputDecoration.collapsed(
                                      hintText: '',
                                    ),
                                  ),
                                ),
                                if (_textController.text.isEmpty)
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Explain what happened',
                                      style: Theming.of(context)
                                          .text
                                          .body
                                          .copyWith(
                                            fontWeight: FontWeight.w300,
                                            color: const Color.fromRGBO(
                                                0xAD, 0xAD, 0xAD, 1.0),
                                          ),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 31.0),
                            child: SizedBox(
                              width: 162,
                              height: 43,
                              child: Button(
                                onPressed: _uploading ? null : _upload,
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(14.5)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theming.of(context)
                                            .shadow
                                            .withOpacity(0.2),
                                        offset: const Offset(0.0, 4.0),
                                        blurRadius: 4.0,
                                      ),
                                    ],
                                    color: Theming.of(context).datingRed2,
                                  ),
                                  child: _uploading
                                      ? const CircularProgressIndicator()
                                      : Text(
                                          'send',
                                          style: Theming.of(context)
                                              .text
                                              .body
                                              .copyWith(fontSize: 18),
                                        ),
                                ),
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
                right: MediaQuery.of(context).padding.right + 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: const HomeButton(
                  color: Colors.white,
                ),
              ),
            ],
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw 'No user is logged in';
    }
    setState(() => _uploading = true);

    final usersApi = ref.read(usersApiProvider);
    final extraText = _textController.text;
    final extra = _reason == _Reason.other
        ? (extraText.isEmpty ? null : extraText)
        : null;
    await usersApi.reportUser(
      uid: user.uid,
      reportedUid: widget.uid,
      reason: _reason.name,
      extra: extra,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully reported user'),
        ),
      );
      Navigator.of(context).pop();
    }
  }
}

enum _Reason { violentRepulsive, harassmentBullying, child, other }

class ReportScreenTheme extends InheritedWidget {
  final ReportScreenThemeData themeData;

  const ReportScreenTheme({
    Key? key,
    required Widget child,
    required this.themeData,
  }) : super(key: key, child: child);

  static ReportScreenThemeData of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ReportScreenTheme>()!
        .themeData;
  }

  @override
  bool updateShouldNotify(ReportScreenTheme oldWidget) =>
      oldWidget.themeData != themeData;
}

@freezed
class ReportScreenThemeData with _$ReportScreenThemeData {
  const factory ReportScreenThemeData({
    required Gradient backgroundGradient,
  }) = _ReportScreenThemeData;
}

class ReportScreenArguments {
  final String uid;

  ReportScreenArguments({
    required this.uid,
  });
}
