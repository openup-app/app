import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
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
    final uid = ref.watch(userProvider.select((s) {
      return s.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn.account.profile.uid,
      );
    }));
    final myEvent = event.host.uid == uid;
    return Column(
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
                child: Container(
                  margin: const EdgeInsets.only(left: 8, right: 20),
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
                ),
              ),
              Expanded(
                child: Column(
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
                        Button(
                          onPressed: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.more_vert),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(13)),
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
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_sharp,
                          size: 16,
                          color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.location.name,
                          style: const TextStyle(
                            color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 10),
                    Button(
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
                      child: Container(
                        width: 157,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: myEvent
                              ? const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0)
                              : const Color.fromRGBO(0xFF, 0xFF, 0xFF, 1.0),
                          borderRadius: const BorderRadius.all(
                            Radius.circular(6),
                          ),
                        ),
                        child: Text(
                          myEvent ? 'Edit Meet' : 'Attend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: myEvent
                                ? Colors.white
                                : const Color.fromRGBO(0x0E, 0x0E, 0x0E, 1.0),
                          ),
                        ),
                      ),
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

class _Participants extends ConsumerWidget {
  final String eventId;

  const _Participants({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(eventParticipantsProvider(eventId));
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
