import 'package:flutter/material.dart';
import 'package:openup/api/api.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/image.dart';

class EventDetails extends StatelessWidget {
  final Event event;
  final bool preview;

  const EventDetails({
    super.key,
    required this.event,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Container(
            width: 184,
            height: 311,
            decoration: BoxDecoration(
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
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${formatDayOfWeek(event.startDate)} | ${formatDateShort(event.startDate)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
              ),
              Expanded(
                child: Text(
                  event.location.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: Color.fromRGBO(0x00, 0x90, 0xE1, 1.0),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${formatTime(event.startDate).toLowerCase()} - ${formatTime(event.endDate).toLowerCase()}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Icon(Icons.attach_money_outlined),
              Expanded(
                child: Text(
                  event.price.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              if (preview)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      return event.attendance.map(
                        unlimited: (_) {
                          return const Text(
                            'Attendance | Unlimited',
                            textAlign: TextAlign.end,
                          );
                        },
                        limited: (limited) {
                          return const Text(
                            'Attendance | Limited',
                            textAlign: TextAlign.end,
                          );
                        },
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.bar_chart_sharp),
                      const SizedBox(width: 4),
                      Text(
                        '${event.views} ${event.views == 1 ? 'view' : 'views'}',
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
        if (!preview) ...[
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Who will be there',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: 20,
              itemBuilder: (context, index) {
                return Button(
                  onPressed: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      child: Container(
                        width: 31,
                        height: 31,
                        foregroundDecoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: Colors.white,
                          ),
                        ),
                        child: Image.network(
                          event.host.photo,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (preview) const SizedBox(height: 35) else const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Event Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            event.description,
            style: const TextStyle(
              height: 1.8,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}
