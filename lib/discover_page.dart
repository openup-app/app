import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/discover/discover_provider.dart';
import 'package:openup/discover_provider.dart';
import 'package:openup/events/event_view_page.dart';
import 'package:openup/location/location_provider.dart';
import 'package:openup/shell_page.dart';
import 'package:openup/widgets/button.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/discover_map_mini_list.dart';
import 'package:openup/widgets/map_display.dart';
import 'package:openup/widgets/map_rendering.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage>
    with SingleTickerProviderStateMixin {
  bool _pageActive = false;

  final _mapKey = GlobalKey<MapDisplayState>();

  final _rendererKey = GlobalKey<MapRenderingState>();
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
          viewProfile: (profile) {
            _mapKey.currentState?.recenterMap(profile.location.latLong);
            ref
                .read(discoverProvider.notifier)
                .idToSelectWhenAvailable(profile.profile.uid);
          },
          viewEvent: (event) {
            _mapKey.currentState?.recenterMap(event.location.latLong);
          },
        );
      },
    );

    ref.listenManual<String?>(discoverAlertProvider, (previous, next) {
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

  AlwaysAliveProviderListenable<DiscoverReadyState?>
      get _discoverReadyProvider {
    return discoverProvider.select((s) {
      return s.map(
        init: (_) => null,
        ready: (ready) => ready,
      );
    });
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

  void _onEventChanged(Event? selectedEvent) {
    ref.read(discoverProvider.notifier).selectEvent(selectedEvent);
  }

  @override
  Widget build(BuildContext context) {
    final readyState = ref.watch(_discoverReadyProvider);
    final events = readyState?.events ?? [];
    final selectedEvent = readyState?.selectedEvent;
    return ActivePage(
      onActivate: () {
        setState(() => _pageActive = true);
        ref.read(discoverProvider.notifier).performQuery();
      },
      onDeactivate: () {
        setState(() => _pageActive = false);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.biggest.height;
              return ColoredBox(
                color: Colors.black,
                child: MapRendering(
                  items: events.map((e) => EventMapItem(e)).toList(),
                  selectedItem: selectedEvent == null
                      ? null
                      : EventMapItem(selectedEvent),
                  frameCount: 12,
                  onMarkerRenderStatus: (status) =>
                      setState(() => _markerRenderStatus = status),
                  builder: (context, renderedItems, renderedSelectedItem) {
                    return MapDisplay(
                      key: _mapKey,
                      items: renderedItems,
                      selectedItem: renderedSelectedItem,
                      onSelectionChanged: (i) =>
                          _onEventChanged((i as EventMapItem?)?.event),
                      itemAnimationSpeedMultiplier: 1.0,
                      initialLocation: Location(
                        latLong: ref.read(locationProvider).initialLatLong,
                        radius: 1800,
                      ),
                      onLocationChanged:
                          ref.read(discoverProvider.notifier).locationChanged,
                      obscuredRatio: 326 / height,
                      onShowRecordPanel: () {},
                    );
                  },
                ),
              );
            },
          ),
          if (!kReleaseMode)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Opacity(
                    opacity: 0.8,
                    child: Button(
                      onPressed: () {
                        if (readyState != null) {
                          ref.read(discoverProvider.notifier).showDebugUsers =
                              !readyState.showDebugUsers;
                        }
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.all(
                            Radius.circular(24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: readyState?.showDebugUsers ?? false,
                              onChanged: (show) {
                                ref
                                    .read(discoverProvider.notifier)
                                    .showDebugUsers = show;
                              },
                            ),
                            const Text(
                              'Fake users',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Consumer(
                              builder: (context, ref, child) {
                                final latLong =
                                    ref.watch(locationProvider).current;
                                return _MapButton(
                                  onPressed: () => _mapKey.currentState
                                      ?.recenterMap(latLong),
                                  child: const Icon(
                                    CupertinoIcons.location_fill,
                                    size: 20,
                                    color:
                                        Color.fromRGBO(0x22, 0x22, 0x22, 1.0),
                                  ),
                                );
                              },
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuart,
                              width: 0,
                              height: selectedEvent == null ? 0 : 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final searching = (readyState?.loading == true ||
                            _markerRenderStatus ==
                                MarkerRenderStatus.rendering);
                        return Button(
                          onPressed: searching
                              ? null
                              : ref
                                  .read(discoverProvider.notifier)
                                  .performQuery,
                          useFadeWheNoPressedCallback: false,
                          child: Container(
                            width: 86,
                            height: 26,
                            padding: const EdgeInsets.only(top: 1),
                            margin: const EdgeInsets.only(bottom: 56),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5)),
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
                              child: searching
                                  ? const IgnorePointer(
                                      child: Center(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                        '${events.length} result${events.length == 1 ? '' : 's'}',
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
                      },
                    ),
                  ],
                ),
                _Panel(
                  gender: readyState?.gender,
                  onGenderChanged: (gender) {
                    ref.read(discoverProvider.notifier).genderChanged(gender);
                    _rendererKey.currentState?.resetMarkers();
                  },
                  events: events,
                  selectedEvent: selectedEvent,
                  onEventChanged: (profile) {
                    ref.read(discoverProvider.notifier).selectEvent(profile);
                  },
                  onBlockUser: (profile) {},
                  pageActive: _pageActive,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends ConsumerStatefulWidget {
  final Gender? gender;
  final ValueChanged<Gender?> onGenderChanged;
  final List<Event> events;
  final Event? selectedEvent;
  final ValueChanged<Event?> onEventChanged;
  final void Function(Profile profile) onBlockUser;
  final bool pageActive;

  const _Panel({
    super.key,
    required this.gender,
    required this.onGenderChanged,
    required this.events,
    required this.selectedEvent,
    required this.onEventChanged,
    required this.onBlockUser,
    required this.pageActive,
  });

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnimationController;

  @override
  void initState() {
    super.initState();
    _sheetAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _sheetAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: ColoredBox(
            color: const Color.fromRGBO(0xFF, 0xFF, 0xFF, 0.4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuart,
                  child: widget.selectedEvent == null
                      ? const SizedBox(
                          width: double.infinity,
                          height: 0,
                        )
                      : _buildMiniProfile(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniProfile() {
    final selectedEvent = widget.selectedEvent;
    if (selectedEvent == null) {
      return const SizedBox(
        height: 0,
        width: double.infinity,
      );
    }
    return DiscoverMapMiniList(
      events: widget.events,
      selectedEvent: selectedEvent,
      onEventChanged: (event) {
        widget.onEventChanged(event);
      },
      onEventPressed: () {
        context.pushNamed(
          'event_view',
          params: {'id': selectedEvent.id},
          extra: EventViewPageArgs(event: selectedEvent),
        );
      },
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
