import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: OpenupAppBar(
        body: OpenupAppBarBody(
          leading: Button(
            onPressed: Navigator.of(context).pop,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Cancel'),
            ),
          ),
          center: const Text('Calendar'),
        ),
      ),
      body: const _Body(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendingEventsState = ref.watch(attendingEventsProvider);
    return attendingEventsState.when(
      loading: () {
        return const Center(
          child: LoadingIndicator(),
        );
      },
      error: () {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Something went wrong'),
              const SizedBox(height: 16),
              RoundedButton(
                onPressed: () => ref.refresh(hostingEventsProvider),
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
      data: (eventIds) {
        if (eventIds.isEmpty) {
          return const _FindEvents(noEvents: true);
        }

        return ListView.separated(
          itemCount: eventIds.length + 1,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            color: Color.fromRGBO(0x1F, 0x1F, 0x1F, 1.0),
          ),
          itemBuilder: (context, index) {
            if (index == eventIds.length) {
              return const SizedBox(
                height: 320,
                child: _FindEvents(noEvents: false),
              );
            }

            final eventId = eventIds[index];
            return EventDisplayListItem(
              event: ref.watch(
                eventProvider(eventId),
              ),
            );
          },
        );
      },
    );
  }
}

class _FindEvents extends StatelessWidget {
  final bool noEvents;
  const _FindEvents({
    super.key,
    required this.noEvents,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 190),
            child: Text(
              noEvents
                  ? 'Doesn’t seem like you are attending any meet ups...\nwould you like to see meet ups?'
                  : 'Would you like to see more events?',
              style: const TextStyle(
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
            width: 160,
            child: RectangleButton(
              onPressed: () => context.goNamed('meetups'),
              child: const Text('Find Meetups'),
            ),
          ),
        ),
      ],
    );
  }
}
