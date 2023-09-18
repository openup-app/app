import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';

class EventPreviewPage extends ConsumerWidget {
  final Event event;

  const EventPreviewPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButton(),
          center: Text('Meetup Preview'),
        ),
      ),
      bottomNavigationBar: OpenupBottomBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            RoundedButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
            RoundedButton(
              onPressed: () async {
                final notifier = ref.read(eventsProvider.notifier);
                final result = await notifier.createEvent(event);
                if (!context.mounted || result == null) {
                  return;
                }
                ref.read(userProvider2.notifier).tempAddEvent(result);
                if (context.mounted) {
                  context.goNamed('meetups');
                }
              },
              color: const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
      body: Builder(
        // Builder to get MediaQuery padding used by scroll view
        builder: (context) {
          return SingleChildScrollView(
            // TODO: Determine why padding isn't being set automatically
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: EventDisplayLarge(
              event: event,
              preview: true,
            ),
          );
        },
      ),
    );
  }
}

class EventPreviewPageArgs {
  final Event event;

  EventPreviewPageArgs({
    required this.event,
  });
}
