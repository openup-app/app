import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';

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
        return EventDisplayListItem(
          event: event,
        );
      },
    );
  }
}
