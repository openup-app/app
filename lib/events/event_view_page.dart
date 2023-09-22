import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/scaffold.dart';

class EventViewPage extends StatelessWidget {
  final Event event;

  const EventViewPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
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
            AttendUnattendButtonBuilder(
              eventId: event.id,
              builder: (context, isParticipating, onPressed) {
                final color = isParticipating ? Colors.white : Colors.black;
                return RoundedButton(
                  color: isParticipating
                      ? const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0)
                      : Colors.white,
                  onPressed: onPressed,
                  child: Builder(
                    builder: (context) {
                      if (onPressed == null) {
                        return LoadingIndicator(
                          color: color,
                        );
                      }
                      return Text(
                        isParticipating ? 'Attending' : 'Attend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: color,
                        ),
                      );
                    },
                  ),
                );
              },
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
