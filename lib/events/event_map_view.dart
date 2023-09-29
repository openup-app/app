import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/event_map_provider.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/map_display.dart';
import 'package:openup/widgets/map_rendering.dart';
import 'package:permission_handler/permission_handler.dart';

class EventMapView extends ConsumerStatefulWidget {
  const EventMapView({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<EventMapView> createState() => _EventMapViewState();
}

class _EventMapViewState extends ConsumerState<EventMapView>
    with SingleTickerProviderStateMixin {
  final _mapKey = GlobalKey<MapDisplayState>();
  MarkerRenderStatus _markerRenderStatus = MarkerRenderStatus.ready;

  bool _firstDidChangeDeps = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual<DiscoverAction?>(
      discoverActionProvider,
      (previous, next) {
        if (next == null) {
          return;
        }

        next.when(
          viewProfile: (profile) {},
          viewEvent: (event) {
            ref.read(eventMapProvider.notifier).showEvent(event);
            _mapKey.currentState?.recenterMap(event.location.latLong);
          },
        );
      },
    );

    ref.listenManual<String?>(eventAlertProvider, (previous, next) {
      if (next == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstDidChangeDeps) {
      _firstDidChangeDeps = false;
      // Location permission also requested from NotificationManager
      _maybeRequestNotification();
    }
  }

  Future<void> _maybeRequestNotification() async {
    final routeCurrent = ModalRoute.of(context)?.isCurrent == true;
    if (!routeCurrent) {
      return;
    }

    final isSignedIn = ref.read(userProvider.select((p) {
      return p.map(
        guest: (_) => false,
        signedIn: (_) => true,
      );
    }));
    if (isSignedIn) {
      final status = await Permission.notification.status;
      if (!(status.isGranted || status.isLimited)) {
        await Permission.notification.request();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () {
        ref.read(eventMapProvider.notifier).fetchEvents();
      },
      onDeactivate: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.biggest.height;
              return ColoredBox(
                color: Colors.black,
                child: MapRendering(
                  items: ref
                      .watch(eventMapProvider.select((s) => s.events))
                      .map((e) => EventMapItem(e))
                      .toList(),
                  selectedItem: ref.watch(eventMapProvider.select((s) =>
                      s.selectedEvent == null
                          ? null
                          : EventMapItem(s.selectedEvent!))),
                  frameCount: 12,
                  onMarkerRenderStatus: (status) =>
                      setState(() => _markerRenderStatus = status),
                  builder: (context, renderedItems, renderedSelectedItem) {
                    return MapDisplay(
                      key: _mapKey,
                      items: renderedItems,
                      selectedItem: renderedSelectedItem,
                      onSelectionChanged: (item) async {
                        if (item != null) {
                          final event = (item as EventMapItem).event;
                          ref.read(eventMapProvider.notifier).selectedEvent =
                              event;
                          await _showEventPanel(event);
                          if (mounted) {
                            ref.read(eventMapProvider.notifier).selectedEvent =
                                null;
                          }
                        }
                      },
                      itemAnimationSpeedMultiplier: 1.0,
                      initialLocation: ref.watch(
                          eventMapProvider.select((s) => s.initialLocation)),
                      onLocationChanged:
                          ref.read(eventMapProvider.notifier).mapMoved,
                      obscuredRatio: 326 / height,
                      onShowRecordPanel: () {},
                    );
                  },
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MapOverlay(
              searching:
                  (ref.watch(eventMapProvider.select((s) => s.refreshing)) ||
                      _markerRenderStatus == MarkerRenderStatus.rendering),
              onRecenterMap: () {
                final latLong = ref.read(locationProvider).current;
                _mapKey.currentState?.recenterMap(latLong);
              },
              onRefetch: ref.read(eventMapProvider.notifier).fetchEvents,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventPanel(Event event) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) {
        return _BottomPanel(
          onClosePressed: Navigator.of(context).pop,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 25),
                    Expanded(
                      child: EventTwoColumnPhoto(event: event),
                    ),
                    const SizedBox(width: 25),
                    Expanded(
                      child: EventTwoColumnDetails(
                        event: event,
                        showMenuButton: false,
                      ),
                    ),
                    const SizedBox(width: 25),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 46,
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 25),
                      Expanded(
                        child: RoundedButton(
                          onPressed: () {
                            context.pushNamed(
                              'event_view',
                              params: {'id': event.id},
                              extra: EventViewPageArgs(event: event),
                            );
                          },
                          color: Colors.white,
                          child: const Text('More Details'),
                        ),
                      ),
                      const SizedBox(width: 25),
                      Expanded(
                        child: AttendUnattendButtonBuilder(
                          eventId: event.id,
                          builder: (context, isParticipating, onPressed) {
                            final color =
                                isParticipating ? Colors.white : Colors.black;
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
                      ),
                      const SizedBox(width: 25),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapOverlay extends ConsumerWidget {
  final bool searching;
  final VoidCallback onRecenterMap;
  final VoidCallback onRefetch;

  const _MapOverlay({
    super.key,
    required this.searching,
    required this.onRecenterMap,
    required this.onRefetch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _MapButton(
                  onPressed: onRecenterMap,
                  child: const Icon(
                    CupertinoIcons.location_fill,
                    size: 20,
                    color: Color.fromRGBO(0x22, 0x22, 0x22, 1.0),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 16,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 72,
          ),
          child: _LoadingRefreshButton(
            onPressed: searching ? null : onRefetch,
            count: searching
                ? null
                : ref.watch(eventMapProvider.select((s) => s.events.length)),
          ),
        ),
      ],
    );
  }
}

class _LoadingRefreshButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final int? count;

  const _LoadingRefreshButton({
    super.key,
    required this.onPressed,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      useFadeWheNoPressedCallback: false,
      child: Container(
        width: 86,
        height: 26,
        padding: const EdgeInsets.only(top: 1),
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(5)),
          color: Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.95),
          boxShadow: [
            BoxShadow(
              blurRadius: 24,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: count == null
              ? const IgnorePointer(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Loading',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(width: 5),
                        LoadingIndicator(
                          color: Colors.black,
                          size: 6.5,
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    '$count result${count == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  final VoidCallback onClosePressed;
  final Widget child;

  const _BottomPanel({
    super.key,
    required this.onClosePressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 13.0),
                  child: Container(
                    width: 47,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(1),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Button(
                    onPressed: onClosePressed,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250 + 24 + 46,
            child: child,
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const _MapButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 4),
            blurRadius: 14,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.15),
          )
        ],
      ),
      child: Button(
        onPressed: onPressed,
        child: OverflowBox(
          minWidth: 56,
          minHeight: 56,
          maxWidth: 56,
          maxHeight: 56,
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class EventMapList extends ConsumerStatefulWidget {
  final List<Event> events;
  final Event? selectedEvent;
  final ValueChanged<Event?> onEventChanged;
  final VoidCallback onEventPressed;

  const EventMapList({
    super.key,
    required this.events,
    required this.selectedEvent,
    required this.onEventChanged,
    required this.onEventPressed,
  });

  @override
  ConsumerState<EventMapList> createState() => _EventMapListState();
}

class _EventMapListState extends ConsumerState<EventMapList> {
  final _pageListener = ValueNotifier<double>(0);
  late final PageController _pageController;
  bool _reportPageChange = true;

  @override
  void initState() {
    super.initState();

    final initialSelectedEvent = widget.selectedEvent;
    final initialIndex = initialSelectedEvent == null
        ? 0
        : widget.events.indexWhere((e) => e.id == initialSelectedEvent.id);
    _pageController = PageController(initialPage: initialIndex);

    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      _pageListener.value = page;
      final selectedEvent = widget.selectedEvent;
      final selectedIndex = selectedEvent == null
          ? 0
          : widget.events.indexWhere((e) => e.id == selectedEvent.id);
      final index = _pageController.page?.round() ?? selectedIndex;
      if (index != selectedIndex && _reportPageChange) {
        widget.onEventChanged(widget.events[index]);
      }
    });
  }

  @override
  void didUpdateWidget(covariant EventMapList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedEvent = widget.selectedEvent;
    final selectedIndex = selectedEvent == null
        ? 0
        : widget.events.indexWhere((e) => e.id == selectedEvent.id);
    final index = _pageController.page?.round() ?? selectedIndex;
    if (index != selectedIndex) {
      setState(() => _reportPageChange = false);
      _pageController
          .animateToPage(
        selectedIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
      )
          .then((_) {
        if (mounted) {
          setState(() => _reportPageChange = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      clipBehavior: Clip.none,
      padEnds: true,
      itemCount: widget.events.length,
      itemBuilder: (context, index) {
        final event = widget.events[index];
        return ListTile(
          onTap: widget.onEventPressed,
          leading: SizedBox(
            width: 48,
            height: 48,
            child: Image.network(
              event.photo.toString(),
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            event.description,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
          trailing: AttendUnattendButtonBuilder(
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
        );
      },
    );
  }
}
