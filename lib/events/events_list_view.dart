import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';

class EventsListPage extends ConsumerWidget {
  const EventsListPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider.select((s) => s.events));
    return ListView.separated(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        bottom: MediaQuery.of(context).padding.bottom + 48,
      ),
      itemCount: events.length,
      separatorBuilder: (_, __) {
        return const Divider(
          color: Color.fromRGBO(0x1F, 0x1F, 0x1F, 1.0),
          height: 1,
        );
      },
      itemBuilder: (context, index) {
        final event = events[index];
        return ColoredBox(
          color: const Color.fromRGBO(0x07, 0x07, 0x07, 1.0),
          child: _EventDisplay(
            event: event,
          ),
        );
      },
    );
  }
}

class _EventDisplay extends StatelessWidget {
  final Event event;

  const _EventDisplay({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
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
                          event.price == 0 ? 'Free' : '${event.price / 100}',
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
                    const Row(
                      children: [
                        Icon(Icons.people_alt_outlined),
                        SizedBox(width: 8),
                        Text(
                          '4 going',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Button(
                      onPressed: () {
                        context.pushNamed(
                          'event_view',
                          params: {'id': event.id},
                          extra: EventViewPageArgs(event: event),
                        );
                      },
                      child: Container(
                        width: 157,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 1.0),
                          borderRadius: BorderRadius.all(
                            Radius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Attend',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Color.fromRGBO(0x0E, 0x0E, 0x0E, 1.0),
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
