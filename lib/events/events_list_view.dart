import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/widgets/common.dart';

class EventsListPage extends ConsumerStatefulWidget {
  const EventsListPage({
    super.key,
  });

  @override
  ConsumerState<EventsListPage> createState() => _EventsListPageState();
}

class _EventsListPageState extends ConsumerState<EventsListPage> {
  @override
  void initState() {
    super.initState();
    final latLong = ref.read(locationProvider).current;
    ref
        .read(eventsProvider.notifier)
        .refreshEvents(Location(latLong: latLong, radius: 1000));
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider.select((s) => s.events));
    if (events.isEmpty) {
      return const _CreateEvent();
    }
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
        return EventDisplayListItem(
          event: event,
        );
      },
    );
  }
}

class _CreateEvent extends StatelessWidget {
  const _CreateEvent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 190),
            child: Text(
              'Doesn\'t seem like there are any nearby meets...\nwould you like to create one? ',
              style: TextStyle(
                height: 1.5,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color.fromRGBO(0xA3, 0xA3, 0xA3, 1.0),
              ),
            ),
          ),
        ),
        Center(
          child: SizedBox(
            width: 121,
            child: RectangleButton(
              onPressed: () => context.pushNamed('meetups_create'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 4),
                  Text('Create'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
