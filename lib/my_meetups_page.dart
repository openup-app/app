import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_display.dart';
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
      body: Builder(
        builder: (context) {
          final events = ref.watch(userProvider.select((s) {
            return s.map(
              guest: (_) => null,
              signedIn: (signedIn) => signedIn.hostingEvents,
            );
          }));
          if (events == null) {
            return const Center(
              child: LoadingIndicator(),
            );
          }

          if (events.isEmpty) {
            return const _CreateEvent(firstEvent: true);
          }

          return ListView.separated(
            itemCount: events.length + 1,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Color.fromRGBO(0x1F, 0x1F, 0x1F, 1.0),
            ),
            itemBuilder: (context, index) {
              if (index == events.length) {
                return const SizedBox(
                  height: 320,
                  child: _CreateEvent(firstEvent: false),
                );
              }

              final event = events[index];
              return EventDisplayListItem(event: event);
            },
          );
        },
      ),
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
