import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/widgets/common.dart';

class EventListView extends ConsumerStatefulWidget {
  final ValueChanged<String> onLabelChanged;

  const EventListView({
    super.key,
    required this.onLabelChanged,
  });

  @override
  ConsumerState<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends ConsumerState<EventListView> {
  final _scrollController = ScrollController();
  final _nearbyEvents = <String>[];
  String? _relativeDate;

  @override
  void initState() {
    super.initState();
    _scrollController
        .addListener(() => _maybeUpdateLabel(_scrollController.offset));
    ref.listenManual(
      nearbyEventsProvider,
      (previous, next) {
        next.map(
          loading: (_) {},
          error: (_) {},
          data: (value) {
            setState(() {
              _nearbyEvents
                ..clear()
                ..addAll(value.eventIds);
            });
            if (_relativeDate == null) {
              _maybeUpdateLabel(0);
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nearbyEventsState = ref.watch(nearbyEventsProvider);
    return nearbyEventsState.when(
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
                onPressed: () => ref.refresh(nearbyEventsProvider),
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      },
      data: (eventIds) {
        if (eventIds.isEmpty) {
          return const _CreateEvent();
        }

        return MasonryGridView.count(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            bottom: MediaQuery.of(context).padding.bottom + 48,
            left: 12,
            right: 12,
          ),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          itemCount: eventIds.length,
          itemBuilder: (context, index) {
            final eventId = eventIds[index];
            return Padding(
              padding: index != 1
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(top: 64.0),
              child: SizedBox(
                width: 181,
                height: 288,
                child: EventGridTile(
                  event: ref.watch(eventProvider(eventId)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _maybeUpdateLabel(double scrollPosition) {
    const itemHeight = 288.0;
    final index = 2 * scrollPosition ~/ itemHeight;
    final event =
        ref.read(eventProvider(_nearbyEvents[index % _nearbyEvents.length]));
    final relativeDate = formatRelativeDate(DateTime.now(), event.startDate);
    if (relativeDate != _relativeDate) {
      setState(() => _relativeDate = relativeDate);
      widget.onLabelChanged(relativeDate);
    }
  }
}

class _CreateEvent extends StatelessWidget {
  const _CreateEvent({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 190),
            child: Text(
              'Doesn\'t seem like there are any nearby Hangouts...\nwould you like to create one? ',
              textAlign: TextAlign.center,
              style: TextStyle(
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
              onPressed: () => context.pushNamed('event_create'),
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
