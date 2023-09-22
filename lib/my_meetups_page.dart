import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';

class MyMeetupsPage extends ConsumerWidget {
  const MyMeetupsPage({super.key});

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
          center: const Text('My Meetups'),
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
    final hostingEventsState = ref.watch(hostingEventsProvider);
    return hostingEventsState.when(
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
          return const _CreateEvent(firstEvent: true);
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
                child: _CreateEvent(firstEvent: false),
              );
            }

            final eventId = eventIds[index];
            return EventDisplayListItem(
              event: ref.watch(eventProvider(eventId)),
            );
          },
        );
      },
    );
  }
}

class _CreateEvent extends StatelessWidget {
  final bool firstEvent;
  const _CreateEvent({
    super.key,
    required this.firstEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 190),
            child: Text(
              firstEvent
                  ? 'Doesn’t seem like you created any meets...\nwould you like to create one? '
                  : 'Doesn’t seem like you created any more meets...\nwould you like to create one? ',
              textAlign: TextAlign.center,
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
