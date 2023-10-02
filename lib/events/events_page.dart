import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/events/event_list_view.dart';
import 'package:openup/events/event_map_view.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/scaffold.dart';
import 'package:openup/widgets/button.dart';

enum _View { list, map }

class EventsPage extends ConsumerStatefulWidget {
  final bool viewMap;
  const EventsPage({
    super.key,
    this.viewMap = false,
  });

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  late _View _view;

  @override
  void initState() {
    super.initState();
    _view = widget.viewMap ? _View.map : _View.list;
  }

  @override
  void didUpdateWidget(covariant EventsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewMap != widget.viewMap) {
      _view = widget.viewMap ? _View.map : _View.list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const OpenupAppBar(
        body: OpenupAppBarBody(
          center: Text('Meetup Scene'),
        ),
        toolbar: _Toolbar(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          switch (_view) {
            _View.list => const EventListView(),
            _View.map => const EventMapView(),
          },
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: 8.0 + MediaQuery.of(context).padding.bottom),
              child: _ViewToggleButton(
                view: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Consumer(builder: (context, ref, child) {
          return Button(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: Colors.black,
                    insetPadding: const EdgeInsets.all(16),
                    content: SizedBox(
                      width: 350,
                      height: 300,
                      child: CalendarDatePicker(
                        initialDate: DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        onDateChanged: (date) {
                          ref
                              .read(nearbyEventsDateFilterProvider.notifier)
                              .date = date;
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_outlined),
                  SizedBox(width: 8),
                  Text(
                    'Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        const SizedBox(
          height: 29,
          child: VerticalDivider(
            width: 1,
            color: Color.fromRGBO(0x50, 0x50, 0x50, 1.0),
          ),
        ),
        const SizedBox(width: 8),
        Consumer(
          builder: (context, ref, child) {
            return Button(
              onPressed: () =>
                  ref.read(nearbyEventsDateFilterProvider.notifier).date = null,
              child: child!,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'All Days',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const Spacer(),
        Button(
          onPressed: () => context.pushNamed('event_create'),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.add),
                SizedBox(width: 4),
                Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final _View view;
  final ValueChanged<_View> onChanged;

  const _ViewToggleButton({
    super.key,
    required this.view,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: () => onChanged(view == _View.map ? _View.list : _View.map),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 89,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 2),
                blurRadius: 17,
                color: Color.fromRGBO(0x00, 0x00, 0x00, 0.5),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                view == _View.list ? Icons.map : Icons.list,
                color: Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                view == _View.list ? 'Map' : 'List',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
