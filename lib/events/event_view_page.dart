import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/events/event_details.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/common.dart';

class EventViewPage extends ConsumerWidget {
  final Event event;

  const EventViewPage({
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
          center: Text('Event Details'),
        ),
      ),
      bottomNavigationBar: OpenupBottomBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on),
                const SizedBox(width: 4),
                Text(
                  event.price.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            RoundedButton(
              onPressed: () async {},
              color: Colors.white,
              child: const Text(
                'Attend',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
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
            child: EventDetails(
              event: event,
              preview: false,
            ),
          );
        },
      ),
    );
  }
}

class EventViewPageArgs {
  final Event event;

  EventViewPageArgs({
    required this.event,
  });
}
