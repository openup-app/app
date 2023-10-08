import 'dart:async';
import 'dart:math';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/events/event_display.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/events/events_provider.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/map_display.dart';
import 'package:openup/widgets/map_rendering.dart';

part 'event_map_view.freezed.dart';

const _initialRadius = 1500.0;

final _mapLocationProvider =
    StateNotifierProvider<_MapLocationNotifier, Location>(
  (ref) {
    return _MapLocationNotifier(
      initialLocation: Location(
        latLong: ref.watch(locationProvider).current,
        radius: _initialRadius,
      ),
    );
  },
  dependencies: [locationProvider],
);

class _MapLocationNotifier extends StateNotifier<Location> {
  Location _prevFetchLocation;

  _MapLocationNotifier({
    required Location initialLocation,
  })  : _prevFetchLocation = initialLocation,
        super(initialLocation);

  void mapMoved(Location location) {
    if (_areLocationsDistant(location, _prevFetchLocation)) {
      refetch(location);
    }
  }

  void refetch(Location location) {
    _prevFetchLocation = location;
    state = location;
  }

  bool _areLocationsDistant(Location a, Location b) {
    // Reduced radius for improved experience when searching
    final panRatio = greatCircleDistance(a.latLong, b.latLong) / a.radius;
    final zoomRatio = b.radius / a.radius;
    final panned = panRatio > 0.5;
    final zoomed = zoomRatio > 2.0 || zoomRatio < 0.5;
    if (panned || zoomed) {
      return true;
    }
    return false;
  }
}

final selectedEventProvider = StateProvider<String?>((ref) => null);

final mapEventsStateProviderInternal = FutureProvider<IList<Event>>(
  (ref) async {
    final api = ref.watch(apiProvider);
    final location = ref.watch(_mapLocationProvider);
    final result = await api.getEvents(location);
    return result.fold(
      (l) => throw l,
      (r) => r.toIList(),
    );
  },
  dependencies: [apiProvider, _mapLocationProvider],
);

final _mapEventsStateProvider = StateProvider<NearbyEventsState>(
  (ref) {
    final eventStoreNotifier = ref.watch(eventStoreProvider.notifier);
    ref.listen(
      mapEventsStateProviderInternal,
      (previous, next) {
        next.when(
          loading: () {},
          error: (_, __) {},
          data: (events) {
            return eventStoreNotifier.state = eventStoreNotifier.state
                .addEntries(events.map((e) => MapEntry(e.id, e)));
          },
        );
      },
    );

    final events = ref.watch(mapEventsStateProviderInternal);
    final storedEventIds =
        ref.watch(eventStoreProvider.select((s) => s.keys.toList()));
    if (events.isRefreshing) {
      return const NearbyEventsState.loading();
    }
    return events.when(
      loading: () => const NearbyEventsState.loading(),
      error: (_, __) => const NearbyEventsState.error(),
      data: (events) {
        final sortedEvents = List.of(events)..sort(dateAscendingEventSorter);
        return NearbyEventsState.data(sortedEvents
            .where((e) => storedEventIds.contains(e.id))
            .map((e) => e.id)
            .toList());
      },
    );
  },
  dependencies: [eventStoreProvider, mapEventsStateProviderInternal],
);

final _mapEventsProvider = Provider<_MapEvents>(
  (ref) {
    return _MapEvents(
      events: ref.watch(_mapEventsStateProvider),
      selectedEvent: ref.watch(selectedEventProvider),
    );
  },
  dependencies: [_mapEventsStateProvider],
);

@freezed
class _MapEvents with _$_MapEvents {
  const factory _MapEvents({
    required NearbyEventsState events,
    required String? selectedEvent,
  }) = __MapEvents;
}

class EventMapView extends ConsumerStatefulWidget {
  final String? initialSelectedEventId;

  const EventMapView({
    Key? key,
    this.initialSelectedEventId,
  }) : super(key: key);

  @override
  ConsumerState<EventMapView> createState() => _EventMapViewState();
}

final _boundsProvider = StateProvider<(LatLong, LatLong)?>((ref) => null);

class _EventMapViewState extends ConsumerState<EventMapView>
    with SingleTickerProviderStateMixin {
  final _mapKey = GlobalKey<MapDisplayState>();
  MarkerRenderStatus _markerRenderStatus = MarkerRenderStatus.ready;

  @override
  void initState() {
    super.initState();

    // Refresh map events on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(mapEventsStateProviderInternal);
      }
    });

    final initialSelectedEventId = widget.initialSelectedEventId;
    if (initialSelectedEventId != null) {
      _showInitialEvent(initialSelectedEventId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActivePage(
      onActivate: () => ref.invalidate(_mapEventsStateProvider),
      onDeactivate: () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.biggest.height;
              final events = ref.watch(
                _mapEventsProvider.select(
                  (s) => s.events.map(
                    loading: (_) => null,
                    error: (_) => null,
                    data: (data) => data.eventIds,
                  ),
                ),
              );
              return ColoredBox(
                color: Colors.black,
                child: MapRendering(
                  items: events == null
                      ? []
                      : events
                          .map((eventId) =>
                              EventMapItem(ref.watch(eventProvider(eventId))))
                          .toList(),
                  selectedItem: ref.watch(selectedEventProvider.select((s) =>
                      s == null
                          ? null
                          : EventMapItem(ref.watch(eventProvider(s))))),
                  frameCount: 12,
                  onMarkerRenderStatus: (status) =>
                      setState(() => _markerRenderStatus = status),
                  builder: (context, renderedItems, renderedSelectedItem) {
                    return MapDisplay(
                      key: _mapKey,
                      items: List.of(renderedItems),
                      selectedItem: renderedSelectedItem,
                      onSelectionChanged: (item) async {
                        if (item != null) {
                          final event = (item as EventMapItem).event;
                          ref.read(selectedEventProvider.notifier).state =
                              event.id;
                          await _showEventPanel(event);
                          if (mounted) {
                            ref.read(selectedEventProvider.notifier).state =
                                null;
                          }
                        }
                      },
                      itemAnimationSpeedMultiplier: 1.0,
                      initialLocation: ref.watch(_mapLocationProvider),
                      onLocationChanged:
                          ref.read(_mapLocationProvider.notifier).mapMoved,
                      onBoundsChanged: (northEast, southWest) => ref
                          .read(_boundsProvider.notifier)
                          .state = (northEast, southWest),
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
            child: Builder(
              builder: (context) {
                final searching = ref.watch(
                  _mapEventsProvider.select(
                    (s) => s.events.map(
                      loading: (_) => true,
                      error: (_) => false,
                      data: (data) => false,
                    ),
                  ),
                );
                return _MapOverlay(
                  searching: searching ||
                      _markerRenderStatus == MarkerRenderStatus.rendering,
                  onRecenterMap: () {
                    final latLong = ref.read(locationProvider).current;
                    _mapKey.currentState?.recenterMap(latLong);
                  },
                  onRefetch: () async {
                    final location =
                        await _mapKey.currentState?.currentLocation();
                    if (location != null) {
                      ref.read(_mapLocationProvider.notifier).refetch(location);
                    }
                  },
                );
              },
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
                          builder: (context, isParticipating, isMyEvent,
                              onPressed, isLoading) {
                            final color =
                                isParticipating ? Colors.white : Colors.black;
                            return RoundedButton(
                              color: isParticipating
                                  ? const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0)
                                  : Colors.white,
                              onPressed: onPressed,
                              child: Builder(
                                builder: (context) {
                                  if (isLoading) {
                                    return LoadingIndicator(
                                      color: color,
                                    );
                                  }
                                  return Text(
                                    isMyEvent
                                        ? 'Edit'
                                        : (isParticipating
                                            ? 'Attending'
                                            : 'Attend'),
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

  void _showInitialEvent(String eventId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final event = ref.read(eventProvider(eventId));
      ref.read(selectedEventProvider.notifier).state =
          widget.initialSelectedEventId;
      final mapLocationNotifier = ref.read(_mapLocationProvider.notifier);
      mapLocationNotifier.mapMoved(
        Location(
          latLong: event.location.latLong,
          radius: _initialRadius,
        ),
      );

      _showEventPanel(event).then((_) {
        if (mounted) {
          ref.read(selectedEventProvider.notifier).state = null;
        }
      });

      // Second post frame callback seems to allow recentering of the map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _mapKey.currentState?.recenterMap(event.location.latLong);
      });
    });
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
          child: Builder(
            builder: (context) {
              final bounds = ref.watch(_boundsProvider);

              final eventIds = ref.watch(
                _mapEventsProvider.select(
                  (s) => s.events.map(
                    loading: (_) => null,
                    error: (_) => [],
                    data: (data) => data.eventIds,
                  ),
                ),
              );

              final int? count;
              if (bounds == null || eventIds == null) {
                count = eventIds?.length;
              } else {
                final northEast = bounds.$1;
                final southWest = bounds.$2;
                final eventsInBounds = eventIds
                    .map((eventId) => ref.read(eventProvider(eventId)))
                    .where((e) =>
                        _isInBounds(e.location.latLong, northEast, southWest));
                count = eventsInBounds.length;
              }

              return _LoadingRefreshButton(
                onPressed: searching ? null : onRefetch,
                count: count,
              );
            },
          ),
        ),
      ],
    );
  }

  // TODO: Not robust, start must be east and end must be west
  bool _isInBounds(LatLong target, LatLong start, LatLong end) {
    double minLat = min(start.latitude, end.latitude);
    double maxLat = max(start.latitude, end.latitude);

    if (target.latitude >= minLat && target.latitude <= maxLat) {
      if (start.longitude >= end.longitude) {
        return target.longitude <= start.longitude &&
            target.longitude >= end.longitude;
      } else {
        return target.longitude <= start.longitude ||
            target.longitude >= end.longitude;
      }
    }
    return false;
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
              event.host.photo,
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
            builder:
                (context, isParticipating, isMyEvent, onPressed, isLoading) {
              final color = isParticipating ? Colors.white : Colors.black;
              return RoundedButton(
                color: isParticipating
                    ? const Color.fromRGBO(0x00, 0x90, 0xE1, 1.0)
                    : Colors.white,
                onPressed: onPressed,
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return LoadingIndicator(
                        color: color,
                      );
                    }
                    return Text(
                      isMyEvent
                          ? 'Edit'
                          : (isParticipating ? 'Attending' : 'Attend'),
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
