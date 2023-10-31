import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_create_page.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/view_profile_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';
import 'package:openup/widgets/record.dart';

class EventDisplayListItem extends ConsumerWidget {
  final Event event;

  const EventDisplayListItem({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        context.pushNamed(
          'event_view',
          pathParameters: {'id': event.id},
          extra: EventViewPageArgs(event: event),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        textStyle: DefaultTextStyle.of(context).style,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 27),
          SizedBox(
            height: 287,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 20),
                    child: EventTwoColumnPhoto(event: event),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      EventTwoColumnDetails(event: event),
                      const SizedBox(height: 10),
                      AttendUnattendButtonBuilder(
                        eventId: event.id,
                        builder: (context, isParticipating, isMyEvent,
                            onPressed, isLoading) {
                          return Button(
                            onPressed: onPressed,
                            child: Container(
                              width: 157,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isParticipating
                                    ? const Color.fromRGBO(
                                        0x00, 0x90, 0xE1, 1.0)
                                    : const Color.fromRGBO(
                                        0xFF, 0xFF, 0xFF, 1.0),
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(6),
                                ),
                              ),
                              child: Builder(
                                builder: (context) {
                                  if (isLoading) {
                                    return Center(
                                      child: LoadingIndicator(
                                        color: isParticipating
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    );
                                  }

                                  return Text(
                                    isMyEvent
                                        ? 'Edit'
                                        : (isParticipating
                                            ? 'Attending'
                                            : 'Attend'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      color: isParticipating
                                          ? Colors.white
                                          : const Color.fromRGBO(
                                              0x0E, 0x0E, 0x0E, 1.0),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              'Event Description',
              style: TextStyle(
                decoration: TextDecoration.underline,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                height: 1.6,
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 21),
        ],
      ),
    );
  }
}

class EventListTile extends ConsumerWidget {
  final Event event;

  const EventListTile({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Button(
      onPressed: () {
        context.pushNamed(
          'event_view',
          pathParameters: {'id': event.id},
          extra: EventViewPageArgs(event: event),
        );
      },
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.black),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        event.host.photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 13,
                      bottom: 12,
                      child: Container(
                        height: 21,
                        clipBehavior: Clip.hardEdge,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(
                            Radius.circular(3),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            _eventAttendanceText(event),
                            style: const TextStyle(
                              color: Color.fromRGBO(0x21, 0x21, 0x21, 1.0),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: Text(
                              event.title,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month,
                                color: Color.fromRGBO(0x65, 0x65, 0x65, 1.0),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${formatDayOfWeek(event.startDate)}, ${formatDateShortAlternative(event.startDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                ' • ${formatTime(event.startDate)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                clipBehavior: Clip.hardEdge,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Image.network(
                                  event.host.photo,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Hosted by ${event.host.name}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Button(
                        onPressed: () {},
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(
                            Icons.more_horiz,
                            color: Color.fromRGBO(0x65, 0x65, 0x65, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class EventTwoColumnPhoto extends StatelessWidget {
  final Event event;

  const EventTwoColumnPhoto({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      foregroundDecoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: ImageUri(
        event.photo,
        fit: BoxFit.cover,
      ),
    );
  }
}

class EventTwoColumnDetails extends ConsumerWidget {
  final Event event;
  final bool showMenuButton;

  const EventTwoColumnDetails({
    super.key,
    required this.event,
    this.showMenuButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            Builder(
              builder: (context) {
                if (ref.watch(uidProvider) != event.host.uid) {
                  return const SizedBox.shrink();
                }
                return Button(
                  onPressed: () async {
                    final delete = await _showDeleteEventModal(context);
                    if (delete && context.mounted) {
                      if (context.mounted && delete == true) {
                        Navigator.of(context).pop();
                        ref
                            .read(eventManagementProvider.notifier)
                            .deleteEvent(event.id);
                      }
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.more_vert),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(13)),
              child: Container(
                width: 26,
                height: 26,
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Image.network(
                  event.host.photo,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                  children: [
                    const TextSpan(text: 'Hosted by '),
                    TextSpan(
                      text: event.host.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Button(
          onPressed: () => _showEventOnMap(context, event),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_sharp,
                size: 16,
                color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event.location.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            children: [
              TextSpan(text: formatDayOfWeek(event.endDate)),
              const TextSpan(text: ' | '),
              TextSpan(
                text: formatDateShort(event.startDate),
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatTime(event.startDate).toLowerCase()} - ${formatTime(event.endDate).toLowerCase()}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 21),
        Row(
          children: [
            const Icon(Icons.monetization_on),
            const SizedBox(width: 8),
            Text(
              event.price == 0 ? 'Free' : '${event.price}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.bar_chart_sharp),
            const SizedBox(width: 8),
            Text(
              '${event.views} views',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.people_alt_outlined),
            const SizedBox(width: 8),
            Text(
              '${event.participants.count} going',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<bool> _showDeleteEventModal(BuildContext context) async {
    final delete = await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250 + MediaQuery.of(context).padding.bottom,
          child: _ModalBackground(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Want to delete your Hangout?'),
                const SizedBox(height: 72),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    RoundedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                    RoundedButton(
                      color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                      onPressed: Navigator.of(context).pop,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom,
                ),
              ],
            ),
          ),
        );
      },
    );

    return delete == true;
  }
}

class EventDisplayLarge extends ConsumerWidget {
  final Event event;
  final bool preview;

  const EventDisplayLarge({
    super.key,
    required this.event,
    required this.preview,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _popIfEventDoesNotExist(context, ref, event.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 512,
          child: Stack(
            children: [
              Positioned.fill(
                child: ImageUri(
                  event.photo,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 115,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${formatDayOfWeek(event.startDate)} | ',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              TextSpan(
                                text: formatDateShort(event.startDate),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const SizedBox(width: 28),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(24)),
              child: Container(
                width: 48,
                height: 48,
                foregroundDecoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: Colors.white),
                ),
                child: Image.network(
                  event.host.photo,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'Hangout hosted by ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      TextSpan(
                        text: event.host.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Builder(
                  builder: (context) {
                    final count = event.attendance.map(
                      limited: (value) => value.limit,
                      unlimited: (value) => null,
                    );
                    final number = count == null
                        ? 'people'
                        : (count == 1 ? '1 person' : '$count people');
                    return Text(
                      'Wants $number to join',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const Divider(
          height: 36,
          indent: 28,
          endIndent: 28,
          color: Color.fromRGBO(0x3B, 0x3B, 0x3B, 1.0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              const Text(
                'What we\'ll do',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${formatTime(event.startDate).toLowerCase()} - ${formatTime(event.endDate).toLowerCase()}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            event.description,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const Divider(
          height: 36,
          indent: 28,
          endIndent: 28,
          color: Color.fromRGBO(0x3B, 0x3B, 0x3B, 1.0),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              const Text(
                'Who will be there',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _eventAttendanceText(event, displayFull: false),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: _Participants(
            event: event,
          ),
        ),
        const Divider(
          height: 36,
          indent: 28,
          endIndent: 28,
          color: Color.fromRGBO(0x3B, 0x3B, 0x3B, 1.0),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Where will it be',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Button(
            onPressed: preview ? null : () => _showEventOnMap(context, event),
            useFadeWheNoPressedCallback: false,
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                  ),
                  Expanded(
                    child: Text(
                      event.location.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class EventDisplayMini extends StatelessWidget {
  final Event event;

  const EventDisplayMini({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 138,
          margin: const EdgeInsets.symmetric(horizontal: 25),
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(
              Radius.circular(13),
            ),
          ),
          child: ImageUri(
            event.photo,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          event.title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.calendar_month,
              color: Color.fromRGBO(0x65, 0x65, 0x65, 1.0),
            ),
            const SizedBox(width: 4),
            Text(
              '${formatDayOfWeek(event.startDate)}, ${formatDateShortAlternative(event.startDate)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              ' • ${formatTime(event.startDate)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: Image.network(
                event.host.photo,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Hosted by ${event.host.name}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _eventAttendanceText(Event event, {bool displayFull = true}) {
  final limit = event.attendance.map(
    unlimited: (_) => null,
    limited: (limit) => limit.limit,
  );
  if (limit == null) {
    return event.participants.count.toString();
  }

  final remaining = limit - event.participants.count;
  if (remaining <= 0 && displayFull) {
    return 'Hangout full';
  }

  return '${event.participants.count} / $limit';
}

void _showEventOnMap(BuildContext context, Event event) {
  context.goNamed(
    'events',
    queryParameters: {
      'view_map': 'true',
      'event_id': event.id,
    },
  );
}

void _popIfEventDoesNotExist(
  BuildContext context,
  WidgetRef ref,
  String eventId,
) {
  try {
    if (eventId.isNotEmpty) {
      ref.watch(eventProvider(eventId));
    }
  } catch (e) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}

class _Participants extends ConsumerWidget {
  final Event event;

  const _Participants({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = event.id.isNotEmpty
        ? ref.watch(eventParticipantsProvider(event.id))
        : AsyncValue.data(IList([
            SimpleProfile(
              uid: event.host.uid,
              name: event.host.name,
              photo: event.host.photo,
            )
          ]));
    if (result.isRefreshing) {
      return const Padding(
        padding: EdgeInsets.only(left: 16.0),
        child: LoadingIndicator(color: Colors.white),
      );
    }

    return result.map(
      loading: (_) {
        return const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: LoadingIndicator(color: Colors.white),
        );
      },
      error: (_) {
        return const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      },
      data: (data) {
        final profiles = data.value;
        return Button(
          onPressed: () async {
            final uid = await _showParticipantsSheet(context, profiles);
            if (context.mounted && uid != null) {
              context.pushNamed(
                'view_profile',
                queryParameters: {'uid': uid},
              );
            }
          },
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 28, right: 28),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return SizedBox(
                width: 24,
                child: OverflowBox(
                  maxWidth: 31,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Container(
                      width: 31,
                      height: 31,
                      clipBehavior: Clip.hardEdge,
                      foregroundDecoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 1,
                          color: Colors.white,
                        ),
                      ),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        profile.photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<String?> _showParticipantsSheet(
    BuildContext context,
    IList<SimpleProfile> profiles,
  ) {
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 250 + MediaQuery.of(context).padding.bottom,
          child: _ModalBackground(
            child: ListView.separated(
              itemCount: profiles.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return ListTile(
                  onTap: () => Navigator.of(context).pop(profile.uid),
                  leading: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(48)),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Image.network(
                        profile.photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class AttendUnattendButtonBuilder extends ConsumerStatefulWidget {
  final String eventId;
  final bool useUnattendModal;
  final Widget Function(BuildContext context, bool participating, bool myEvent,
      VoidCallback? onPressed, bool isLoading) builder;

  const AttendUnattendButtonBuilder({
    super.key,
    required this.eventId,
    this.useUnattendModal = true,
    required this.builder,
  });

  @override
  ConsumerState<AttendUnattendButtonBuilder> createState() =>
      _AttendUnattendButtonBuilderState();
}

class _AttendUnattendButtonBuilderState
    extends ConsumerState<AttendUnattendButtonBuilder> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(uidProvider);
    final event = ref.watch(eventProvider(widget.eventId));
    final isMyEvent = event.host.uid == uid;
    final isParticipating = event.participants.uids.contains(uid);
    final isFull = event.attendance.map(
      unlimited: (_) => false,
      limited: (limit) {
        final remaining = limit.limit - event.participants.count;
        return remaining <= 0;
      },
    );

    final VoidCallback? onPressed;
    if (isMyEvent) {
      onPressed = () {
        context.pushNamed(
          'event_create',
          extra: EventCreateArgs(editEvent: event),
        );
      };
    } else if (_loading || (isFull && !isParticipating)) {
      onPressed = null;
    } else {
      onPressed = () async {
        if (widget.useUnattendModal && isParticipating) {
          final confirmUnattend =
              await showUnattendingModal(context, widget.eventId);
          if (!(mounted && confirmUnattend == true)) {
            return;
          }
        }
        setState(() => _loading = true);
        await ref
            .read(eventManagementProvider.notifier)
            .updateEventParticipation(widget.eventId, !isParticipating);
        if (!mounted) {
          return;
        }
        setState(() => _loading = false);

        if (!isParticipating) {
          showAttendingModal(
            context,
            ref.read(eventProvider(widget.eventId)),
          );
        }
      };
    }
    return widget.builder(
        context, isParticipating, isMyEvent, onPressed, _loading);
  }
}

Future<bool?> showUnattendingModal(BuildContext context, String eventId) {
  return showCupertinoModalPopup<bool>(
    context: context,
    builder: (context) {
      return Container(
        height: 240 + MediaQuery.of(context).padding.top,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(0x00, 0x00, 0x00, 0.8),
              Color.fromRGBO(0x00, 0x00, 0x00, 0.3),
            ],
          ),
        ),
        child: _UnattendModal(
          eventId: eventId,
        ),
      );
    },
  );
}

Future<bool?> showAttendingModal(BuildContext context, Event event) {
  return showCupertinoModalPopup<bool>(
    context: context,
    builder: (context) {
      return Container(
        height: 330 + MediaQuery.of(context).padding.bottom,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _AttendingModal(event: event),
            ),
            const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 48,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      );
    },
  );
}

class _UnattendModal extends StatelessWidget {
  final String eventId;

  const _UnattendModal({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BlurredSurface(
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16),
            child: Stack(
              children: [
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 37.0),
                    child: Text(
                      'Are you still attending\nthis Hangout?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.3,
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 11),
                    child: Container(
                      width: 47,
                      height: 2,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(71),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      RoundedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('No'),
                      ),
                      RoundedButton(
                        color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                        onPressed: Navigator.of(context).pop,
                        child: const Text('Yes'),
                      ),
                    ],
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

class _AttendingModal extends ConsumerWidget {
  final Event event;

  const _AttendingModal({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRect(
      child: BlurredSurface(
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        height: 1.3,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      children: [
                        const TextSpan(
                          text: 'Would you like to introduce yourself to ',
                        ),
                        TextSpan(
                          text: event.host.name,
                          style: const TextStyle(
                            color: Color.fromRGBO(0x00, 0xA3, 0xFF, 1.0),
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap =
                                () => _popAndNavigateToProfile(context, event),
                        ),
                        const TextSpan(
                          text: '?',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Button(
                onPressed: () => _popAndNavigateToProfile(context, event),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      clipBehavior: Clip.hardEdge,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        event.host.photo,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.host.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SvgPicture.asset(
                          'assets/images/chevron_right.svg',
                          colorFilter: const ColorFilter.mode(
                            Color.fromRGBO(0x3E, 0x3E, 0x3E, 1.0),
                            BlendMode.srcIn,
                          ),
                          height: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Button(
                onPressed: () async {
                  await _showRecordPanel(
                      context, ref.read(userProvider.notifier));
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 53,
                  clipBehavior: Clip.hardEdge,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                    borderRadius: BorderRadius.all(
                      Radius.circular(6),
                    ),
                  ),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    child: const Text('Message'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _popAndNavigateToProfile(BuildContext context, Event event) {
    Navigator.of(context).pop();
    context.pushNamed(
      'view_profile',
      queryParameters: {'uid': event.host.uid},
      extra: ViewProfilePageArguments.uid(uid: event.host.uid),
    );
  }

  Future<void> _showRecordPanel(
    BuildContext context,
    UserStateNotifier notifier,
  ) async {
    final result = await showRecordPanel(
      context: context,
      title: const Text('Recording Message'),
      submitLabel: const Text('Tap to send'),
    );
    if (result == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }

    await withBlockingModal(
      context: context,
      label: 'Sending invite...',
      future: notifier.sendMessage(uid: event.host.uid, audio: result.audio),
    );
    notifier.refreshChatrooms();
  }
}

class _ModalBackground extends StatelessWidget {
  final Widget child;

  const _ModalBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BlurredSurface(
        child: Material(
          type: MaterialType.transparency,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Stack(
              children: [
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    height: 1.3,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  child: child,
                ),
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: 48,
                      height: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(2)),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
