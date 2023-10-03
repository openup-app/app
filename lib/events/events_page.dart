import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Widget? _label;
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
      appBar: OpenupAppBar(
        body: const OpenupAppBarBody(
          center: Text('Hangouts Nearby'),
        ),
        toolbar: _Toolbar(
          label: _label ?? const SizedBox.shrink(),
          view: _view,
          onViewChanged: (view) => setState(() => _view = view),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          switch (_view) {
            _View.list => EventListView(
                onLabelChanged: (label) => setState(() => _label = Text(label)),
              ),
            _View.map => const EventMapView(),
          },
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final Widget label;
  final _View view;
  final ValueChanged<_View> onViewChanged;

  const _Toolbar({
    super.key,
    required this.label,
    required this.view,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 24),
        Consumer(
          builder: (context, ref, child) {
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
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'Covered By Your Grace',
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                  child: label,
                ),
              ),
            );
          },
        ),
        const Spacer(),
        _ViewToggleButton(
          view: view,
          onChanged: onViewChanged,
        ),
        const SizedBox(width: 32),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              view == _View.list ? Icons.map : Icons.list,
            ),
            const SizedBox(width: 8),
            Text(
              view == _View.list ? 'Map' : 'List',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
