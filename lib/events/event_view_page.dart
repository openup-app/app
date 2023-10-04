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
        blurBackground: false,
        body: OpenupAppBarBody(
          leading: OpenupAppBarBackButtonOutlined(),
        ),
      ),
      bottomNavigationBar: OpenupBottomBar(
        child: Row(
          children: [
            const SizedBox(width: 28),
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '\$${event.price.toString()}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: ' / person',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: AttendUnattendButtonBuilder(
                eventId: event.id,
                builder: (context, isParticipating, onPressed, isLoading) {
                  final color = isParticipating ? Colors.black : Colors.white;
                  return RoundedButton(
                    color: isParticipating
                        ? Colors.white
                        : const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                    onPressed: onPressed,
                    child: Builder(
                      builder: (context) {
                        if (isLoading) {
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
            ),
            const SizedBox(width: 28),
          ],
        ),
      ),
      body: Builder(
        // Builder to get MediaQuery padding used by scroll view
        builder: (context) {
          return SingleChildScrollView(
            // TODO: Determine why padding isn't being set automatically
            padding: EdgeInsets.only(
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
