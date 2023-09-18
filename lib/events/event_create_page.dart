import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_preview_page.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';

part 'event_create_page.freezed.dart';

final eventCreationProvider =
    StateNotifierProvider<EventStateNotifier, EventCreationState>(
        (ref) => throw 'Uninitialized provider');

class EventStateNotifier extends StateNotifier<EventCreationState> {
  EventStateNotifier(EventCreationState initialState) : super(initialState);

  set title(String value) => state = state.copyWith(title: value);

  set startDate(DateTime value) {
    final duration = state.endDate.difference(state.startDate);
    state = state.copyWith(
      startDate: value,
      endDate: value.add(duration),
    );
  }

  set endDate(DateTime value) {
    state = state.copyWith(
      startDate: state.startDate.isAfter(value)
          ? value.subtract(const Duration(minutes: 1))
          : state.startDate,
      endDate: value,
    );
  }

  set price(int value) => state = state.copyWith(price: value);

  set attendance(EventAttendance attendance) =>
      state = state.copyWith(attendance: attendance);

  set description(String value) => state = state.copyWith(description: value);

  set photo(Uri value) => state = state.copyWith(photo: value);

  Event? toPreviewEvent(String uid, String name, String photo) {
    final eventPhoto = state.photo;
    if (eventPhoto == null) {
      return null;
    }
    return Event(
      id: '',
      title: state.title,
      host: HostDetails(
        uid: uid,
        name: name,
        photo: photo,
      ),
      location: state.location,
      startDate: state.startDate,
      endDate: state.endDate,
      photo: eventPhoto,
      price: state.price,
      views: 0,
      attendance: state.attendance,
      description: state.description,
    );
  }
}

@freezed
class EventCreationState with _$EventCreationState {
  const factory EventCreationState({
    @Default('') String title,
    @Default(EventLocation(latLong: null, name: '')) EventLocation location,
    required DateTime startDate,
    required DateTime endDate,
    @Default(0) int price,
    @Default(true) bool limitedAttendance,
    @Default(EventAttendance.limited(2)) EventAttendance attendance,
    @Default('') String description,
    @Default(null) Uri? photo,
  }) = _EventCreationState;
}

class EventCreatePage extends ConsumerStatefulWidget {
  final Event? event;

  const EventCreatePage({
    super.key,
    this.event,
  });

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<EventCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _costController;
  late final TextEditingController _attendanceController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    final initialEvent = ref.read(eventCreationProvider);
    _titleController = TextEditingController(text: initialEvent.title);
    _locationController =
        TextEditingController(text: initialEvent.location.name);
    _costController =
        TextEditingController(text: initialEvent.price.toString());
    final attendance = ref.read(eventCreationProvider).attendance;
    final limit = attendance.map(
      unlimited: (_) => null,
      limited: (limited) => limited.limit.toString(),
    );
    _attendanceController = TextEditingController(text: limit);
    _descriptionController =
        TextEditingController(text: initialEvent.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _costController.dispose();
    _attendanceController.dispose();

    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButton(),
          center: Text('Create a Meetup'),
        ),
        blurBackground: true,
      ),
      bottomNavigationBar: OpenupBottomBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RoundedButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            RoundedButton(
              color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
              onPressed: ref.watch(
                      eventCreationProvider.select((s) => s.photo == null))
                  ? null
                  : _showEventPreview,
              child: const Text('Preview'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                _Input(
                  title: const Text('Meetup name'),
                  trailing: _TextField(
                      controller: _titleController,
                      onChanged: (value) => ref
                          .read(eventCreationProvider.notifier)
                          .title = value),
                ),
                _Input(
                  title: const Text('Location'),
                  trailing: _TextField(
                    controller: _locationController,
                  ),
                ),
                _Input(
                  title: const Text('Date'),
                  trailing: _DateField(
                    date: ref.watch(
                        eventCreationProvider.select((s) => s.startDate)),
                  ),
                  onPressed: () async {
                    final startDate = ref.read(eventCreationProvider).startDate;
                    final result = await _showDateDialog(startDate);
                    if (result != null && mounted) {
                      ref.read(eventCreationProvider.notifier).startDate =
                          result;
                    }
                  },
                ),
                _Input(
                  title: const Text('Time'),
                  trailing: _TimeField(
                    start: ref.watch(
                        eventCreationProvider.select((s) => s.startDate)),
                    end: ref
                        .watch(eventCreationProvider.select((s) => s.endDate)),
                  ),
                  onPressed: () async {
                    final startDate = ref.read(eventCreationProvider).startDate;
                    final result = await _showTimeDialog(startDate);
                    if (result != null && mounted) {
                      ref.read(eventCreationProvider.notifier).startDate =
                          result;
                    }
                  },
                ),
                _Input(
                  title: const Text('Cost'),
                  trailing: _TextField(
                    controller: _costController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final price = int.tryParse(value);
                      if (price != null) {
                        ref.read(eventCreationProvider.notifier).price = price;
                      }
                    },
                  ),
                ),
                _Input(
                  title: const Text('Attendance'),
                  trailing: Builder(
                    builder: (context) {
                      final attendance = ref.watch(
                          eventCreationProvider.select((s) => s.attendance));
                      return attendance.map(
                        unlimited: (_) {
                          return Button(
                            onPressed: () {
                              ref
                                      .read(eventCreationProvider.notifier)
                                      .attendance =
                                  EventAttendance.limited(int.tryParse(
                                          _attendanceController.text) ??
                                      2);
                            },
                            child: const SizedBox(
                              height: 48,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Unimilted',
                                ),
                              ),
                            ),
                          );
                        },
                        limited: (_) {
                          return Row(
                            children: [
                              Expanded(
                                child: _TextField(
                                  textAlign: TextAlign.end,
                                  controller: _attendanceController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final limit = int.tryParse(value);
                                    if (limit != null) {
                                      final attendance = ref
                                          .read(eventCreationProvider)
                                          .attendance;
                                      attendance.map(
                                        unlimited: (_) {},
                                        limited: (limited) => ref
                                                .read(eventCreationProvider
                                                    .notifier)
                                                .attendance =
                                            limited.copyWith(limit: limit),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Button(
                                onPressed: () {
                                  ref
                                          .read(eventCreationProvider.notifier)
                                          .attendance =
                                      const EventAttendance.unlimited();
                                },
                                child: const SizedBox(
                                  height: 48,
                                  child: Center(
                                    child: Text('Limited'),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                const _SectionTitle('Description'),
                _FieldBackground(
                  onPressed: () => FocusScope.of(context).requestFocus(),
                  child: _TextField(
                    controller: _descriptionController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.sentences,
                    textAlign: TextAlign.start,
                    hintText: 'Write your description here...',
                    lines: 4,
                    onChanged: (value) => ref
                        .read(eventCreationProvider.notifier)
                        .description = value,
                  ),
                ),
                const _SectionTitle('Photo'),
                _FieldBackground(
                  onPressed: () => _selectPhoto(),
                  child: Builder(
                    builder: (context) {
                      final photo = ref
                          .watch(eventCreationProvider.select((s) => s.photo));
                      return SizedBox(
                        height: 125,
                        child: photo == null
                            ? const Center(
                                child: Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Color.fromRGBO(0x92, 0x92, 0x92, 1.0),
                                  size: 48,
                                ),
                              )
                            : Builder(
                                builder: (context) {
                                  return Center(
                                    child: Container(
                                      width: 62,
                                      height: 105,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      foregroundDecoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: ImageUri(
                                        photo,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _showDateDialog(DateTime initialValue) async {
    DateTime output = initialValue;
    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () {
            Navigator.of(context).pop(output);
            return Future.value(false);
          },
          child: Container(
            color: Colors.black,
            child: SizedBox(
              height: 400,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialValue,
                onDateTimeChanged: (dateTime) => output = dateTime,
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      return initialValue.copyWith(
        year: result.year,
        month: result.month,
        day: result.day,
      );
    }
    return null;
  }

  Future<DateTime?> _showTimeDialog(DateTime initialValue) async {
    DateTime output = initialValue;
    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return WillPopScope(
          onWillPop: () {
            Navigator.of(context).pop(output);
            return Future.value(false);
          },
          child: Container(
            color: Colors.black,
            child: SizedBox(
              height: 400,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: initialValue,
                onDateTimeChanged: (dateTime) => output = dateTime,
              ),
            ),
          ),
        );
      },
    );
    if (result != null) {
      return result.copyWith(
        year: initialValue.year,
        month: initialValue.month,
        day: initialValue.day,
      );
    }
    return null;
  }

  void _selectPhoto() async {
    final photo = await selectPhoto(context);
    if (!mounted || photo == null) {
      return;
    }

    ref.read(eventCreationProvider.notifier).photo = photo.uri;
  }

  void _showEventPreview() {
    final userState = ref.read(userProvider2);
    final myProfile = userState.map(
      guest: (_) => null,
      signedIn: (signedIn) => signedIn.account.profile,
    );
    if (myProfile == null) {
      return;
    }
    final previewEvent =
        ref.read(eventCreationProvider.notifier).toPreviewEvent(
              myProfile.uid,
              myProfile.name,
              myProfile.photo,
            );
    if (previewEvent == null) {
      return;
    }
    context.pushNamed(
      'event_preview',
      extra: EventPreviewPageArgs(event: previewEvent),
    );
  }
}

class _Input extends StatelessWidget {
  final Widget title;
  final Widget trailing;
  final VoidCallback? onPressed;

  const _Input({
    super.key,
    required this.title,
    required this.trailing,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldBackground(
      onPressed: onPressed ?? FocusScope.of(context).requestFocus,
      child: DefaultTextStyle(
        textAlign: TextAlign.end,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              title,
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Builder(
                    builder: (context) {
                      return DefaultTextStyle(
                        style: DefaultTextStyle.of(context).style.copyWith(
                            color: const Color.fromRGBO(0x00, 0x7C, 0xEE, 1.0)),
                        child: trailing,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;
  final String? hintText;
  final int lines;
  final ValueChanged<String>? onChanged;

  const _TextField({
    super.key,
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.words,
    this.textAlign = TextAlign.end,
    this.hintText,
    this.lines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: textInputAction,
      textCapitalization: TextCapitalization.words,
      keyboardType: keyboardType,
      textAlign: textAlign,
      minLines: lines,
      maxLines: lines,
      onChanged: onChanged,
      style: DefaultTextStyle.of(context).style.copyWith(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: DefaultTextStyle.of(context)
            .style
            .copyWith(color: const Color.fromRGBO(0x77, 0x77, 0x77, 1.0)),
        border: InputBorder.none,
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime date;

  const _DateField({
    super.key,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.end,
      text: TextSpan(
        children: [
          TextSpan(
            text: '${formatDayOfWeek(date)} | ',
            style: const TextStyle(
              fontWeight: FontWeight.w300,
            ),
          ),
          TextSpan(
            text: formatDateShort(date),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final DateTime start;
  final DateTime end;

  const _TimeField({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatTime(start).toLowerCase()} - ${formatTime(end).toLowerCase()}',
      textAlign: TextAlign.end,
    );
  }
}

class _FieldBackground extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _FieldBackground({
    super.key,
    this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
        horizontal: 8,
      ),
      child: Button(
        onPressed: onPressed,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(0x2A, 0x2A, 0x2A, 1.0),
            borderRadius: BorderRadius.all(
              Radius.circular(9),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18.0,
              vertical: 4,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(
    this.label, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, top: 20, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color.fromRGBO(0xB3, 0xB3, 0xB3, 1.0),
        ),
      ),
    );
  }
}
