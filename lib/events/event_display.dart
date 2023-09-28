import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/events/event_create_page.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';

class EventDisplayListItem extends ConsumerWidget {
  final Event event;

  const EventDisplayListItem({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(uidProvider);
    final myEvent = event.host.uid == uid;
    return ElevatedButton(
      onPressed: () {
        if (myEvent) {
          context.pushNamed(
            'meetups_create',
            extra: EventCreateArgs(editEvent: event),
          );
        } else {
          context.pushNamed(
            'event_view',
            params: {'id': event.id},
            extra: EventViewPageArgs(event: event),
          );
        }
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
                        builder: (context, isParticipating, onPressed) {
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
                                  if (onPressed == null) {
                                    return Center(
                                      child: LoadingIndicator(
                                        color: isParticipating
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    );
                                  }

                                  return Text(
                                    isParticipating ? 'Attending' : 'Attend',
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
            if (showMenuButton)
              ReportBlockPopupMenu2(
                uid: event.host.uid,
                name: event.host.name,
                onBlock: () {
                  // TODO: Remove event from local list
                },
                builder: (context) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.more_vert),
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
          onPressed: () => _showEventOnMap(context, ref, event),
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
}

class EventDisplayLarge extends StatelessWidget {
  final Event event;
  final bool preview;

  const EventDisplayLarge({
    super.key,
    required this.event,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 184,
            height: 311,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ImageUri(
              event.photo,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${formatDayOfWeek(event.startDate)} | ${formatDateShort(event.startDate)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Consumer(
            builder: (context, ref, child) {
              return Button(
                onPressed: () => _showEventOnMap(context, ref, event),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                    ),
                    Expanded(
                      child: Text(
                        event.location.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${formatTime(event.startDate).toLowerCase()} - ${formatTime(event.endDate).toLowerCase()}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.attach_money_outlined),
              Expanded(
                child: Text(
                  event.price.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (preview)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      return event.attendance.map(
                        unlimited: (_) {
                          return const Text(
                            'Attendance | Unlimited',
                            textAlign: TextAlign.end,
                          );
                        },
                        limited: (limited) {
                          return const Text(
                            'Attendance | Limited',
                            textAlign: TextAlign.end,
                          );
                        },
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.bar_chart_sharp),
                      const SizedBox(width: 4),
                      Text(
                        '${event.views} ${event.views == 1 ? 'view' : 'views'}',
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
        if (!preview) ...[
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Who will be there',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: _Participants(
              eventId: event.id,
            ),
          ),
        ],
        if (preview) const SizedBox(height: 35) else const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Event Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            event.description,
            style: const TextStyle(
              height: 1.8,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}

void _showEventOnMap(BuildContext context, WidgetRef ref, Event event) {
  ref.read(discoverActionProvider.notifier).state =
      DiscoverAction.viewEvent(event);
  context.goNamed(
    'meetups',
    queryParams: {'view_map': 'true'},
  );
}

class _Participants extends ConsumerWidget {
  final String eventId;

  const _Participants({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(eventParticipantsProvider(eventId));
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
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: profiles.length,
          itemBuilder: (context, index) {
            final profile = profiles[index];
            return Button(
              onPressed: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: Container(
                    width: 31,
                    height: 31,
                    foregroundDecoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: Colors.white,
                      ),
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
        );
      },
    );
  }
}

class AttendUnattendButtonBuilder extends ConsumerStatefulWidget {
  final String eventId;
  final bool useUnattendModal;
  final Widget Function(
          BuildContext context, bool participating, VoidCallback? onPressed)
      builder;

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
    final isParticipating = ref.watch(eventProvider(widget.eventId)
        .select((e) => e.participants.uids.contains(uid)));
    return widget.builder(
      context,
      isParticipating,
      _loading
          ? null
          : () async {
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
              if (mounted) {
                setState(() => _loading = false);
              }
            },
    );
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
                      'Are you still attending\nthis event?',
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
