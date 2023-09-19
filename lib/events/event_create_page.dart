import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_preview_page.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/util/photo_picker.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';

final _submissionProvider =
    StateNotifierProvider<_EventCreationStateNotifier, EventSubmission>(
        (ref) => throw 'Uninitialized provider');

class _EventCreationStateNotifier extends StateNotifier<EventSubmission> {
  _EventCreationStateNotifier(EventSubmission submission) : super(submission);

  set title(String value) => state = state.copyWith(title: value);

  set location(EventLocation location) =>
      state = state.copyWith(location: location);

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
}

class EventCreatePage extends ConsumerStatefulWidget {
  final Event? editEvent;

  const EventCreatePage({
    super.key,
    this.editEvent,
  });

  @override
  ConsumerState<EventCreatePage> createState() => _EventCreatePage0State();
}

class _EventCreatePage0State extends ConsumerState<EventCreatePage> {
  late EventSubmission initialSubmission;

  @override
  void initState() {
    super.initState();
    final editEvent = widget.editEvent;
    if (editEvent == null) {
      final now = DateTime.now();
      initialSubmission = EventSubmission(
        location: EventLocation(
          latLong: ref.read(locationProvider).current,
          name: '',
        ),
        startDate: now.add(const Duration(hours: 1)),
        endDate: now.add(const Duration(hours: 3)),
      );
    } else {
      initialSubmission = EventSubmission(
        title: editEvent.title,
        location: editEvent.location,
        startDate: editEvent.startDate,
        endDate: editEvent.endDate,
        photo: editEvent.photo,
        price: editEvent.price,
        attendance: editEvent.attendance,
        description: editEvent.description,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      parent: ProviderScope.containerOf(context),
      overrides: [
        _submissionProvider.overrideWith(
            (ref) => _EventCreationStateNotifier(initialSubmission)),
      ],
      child: _EventCreatePageInternal(
        editingEventId: widget.editEvent?.id,
      ),
    );
  }
}

class _EventCreatePageInternal extends ConsumerStatefulWidget {
  final String? editingEventId;

  const _EventCreatePageInternal({
    super.key,
    this.editingEventId,
  });

  @override
  ConsumerState<_EventCreatePageInternal> createState() =>
      _EventCreatePageState();
}

class _EventCreatePageState extends ConsumerState<_EventCreatePageInternal> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _costController;
  late final TextEditingController _attendanceController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();

    final submission = ref.read(_submissionProvider);
    _titleController = TextEditingController(text: submission.title);
    _locationController = TextEditingController(text: submission.location.name);
    _costController = TextEditingController(text: submission.price.toString());
    final limit = submission.attendance.map(
      unlimited: (_) => null,
      limited: (limited) => limited.limit.toString(),
    );
    _attendanceController = TextEditingController(text: limit);
    _descriptionController =
        TextEditingController(text: submission.description);
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
    final editing = widget.editingEventId != null;
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: OpenupAppBar(
        body: OpenupAppBarBody(
          leading: const OpenupAppBarBackButton(),
          center: editing
              ? const Text('Edit Meetup')
              : const Text('Create a Meetup'),
        ),
        blurBackground: true,
      ),
      bottomNavigationBar: OpenupBottomBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (!editing)
              RoundedButton(
                onPressed: Navigator.of(context).pop,
                child: const Text('Cancel'),
              )
            else
              RoundedButton(
                onPressed: widget.editingEventId == null
                    ? null
                    : () => _showDeleteModal(widget.editingEventId!),
                child: const Text('Delete Meet'),
              ),
            if (!editing)
              RoundedButton(
                color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                onPressed:
                    ref.watch(_submissionProvider.select((s) => !s.valid))
                        ? null
                        : _showEventPreview,
                child: const Text('Preview'),
              )
            else
              RoundedButton(
                color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                onPressed:
                    ref.watch(_submissionProvider.select((s) => !s.valid))
                        ? null
                        : _performUpdate,
                child: const Text('Update Meet'),
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
                      onChanged: (value) =>
                          ref.read(_submissionProvider.notifier).title = value),
                ),
                _Input(
                  title: const Text('Location'),
                  trailing: _TextField(
                    controller: _locationController,
                    onChanged: (value) {
                      final location = ref.read(_submissionProvider).location;
                      ref.read(_submissionProvider.notifier).location =
                          location.copyWith(name: value);
                    },
                  ),
                ),
                _Input(
                  title: const Text('Date'),
                  trailing: _DateField(
                    date: ref
                        .watch(_submissionProvider.select((s) => s.startDate)),
                  ),
                  onPressed: () async {
                    final startDate = ref.read(_submissionProvider).startDate;
                    final result = await _showDateDialog(startDate);
                    if (result != null && mounted) {
                      ref.read(_submissionProvider.notifier).startDate = result;
                    }
                  },
                ),
                _Input(
                  title: const Text('Time'),
                  trailing: _TimeField(
                    start: ref
                        .watch(_submissionProvider.select((s) => s.startDate)),
                    end:
                        ref.watch(_submissionProvider.select((s) => s.endDate)),
                  ),
                  onPressed: () async {
                    final startDate = ref.read(_submissionProvider).startDate;
                    final result = await _showTimeDialog(startDate);
                    if (result != null && mounted) {
                      ref.read(_submissionProvider.notifier).startDate = result;
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
                        ref.read(_submissionProvider.notifier).price = price;
                      }
                    },
                  ),
                ),
                _Input(
                  title: const Text('Attendance'),
                  trailing: Builder(
                    builder: (context) {
                      final attendance = ref.watch(
                          _submissionProvider.select((s) => s.attendance));
                      return attendance.map(
                        unlimited: (_) {
                          return Button(
                            onPressed: () {
                              ref
                                      .read(_submissionProvider.notifier)
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
                                          .read(_submissionProvider)
                                          .attendance;
                                      attendance.map(
                                        unlimited: (_) {},
                                        limited: (limited) =>
                                            ref
                                                    .read(_submissionProvider
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
                                          .read(_submissionProvider.notifier)
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
                        .read(_submissionProvider.notifier)
                        .description = value,
                  ),
                ),
                const _SectionTitle('Photo'),
                _FieldBackground(
                  onPressed: () => _selectPhoto(),
                  child: Builder(
                    builder: (context) {
                      final photo =
                          ref.watch(_submissionProvider.select((s) => s.photo));
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
                            : Center(
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

    ref.read(_submissionProvider.notifier).photo = photo.uri;
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
    final submission = ref.read(_submissionProvider);
    if (!submission.valid) {
      return;
    }
    final event = ref
        .read(_submissionProvider)
        .toPreviewEvent(myProfile.uid, myProfile.name, myProfile.photo);
    context.pushNamed(
      'event_preview',
      extra: EventPreviewPageArgs(
        event: event,
        submission: submission,
      ),
    );
  }

  void _performUpdate() async {
    final editingEventId = widget.editingEventId;
    final submission = ref.read(_submissionProvider);
    if (!submission.valid || editingEventId == null) {
      return;
    }
    final future = ref
        .read(userProvider2.notifier)
        .updateEvent(editingEventId, submission);
    await withBlockingModal(
      context: context,
      label: 'Updating event',
      future: future,
    );

    if (mounted) {
      context.goNamed('meetups');
    }
  }

  void _showDeleteModal(String eventId) async {
    final deleteFuture = await showCupertinoDialog<Future<void>>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          content: const Text('Are you sure you want to delete your event?'),
          actions: [
            CupertinoDialogAction(
              onPressed: () async {
                Navigator.of(context)
                    .pop(ref.read(userProvider2.notifier).deleteEvent(eventId));
              },
              isDestructiveAction: true,
              child: const Text('Delete'),
            ),
            CupertinoDialogAction(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (deleteFuture == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    await withBlockingModal(
      context: context,
      label: 'Deleting event',
      future: deleteFuture,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
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

class EventCreateArgs {
  final Event? editEvent;

  EventCreateArgs({
    this.editEvent,
  });
}
