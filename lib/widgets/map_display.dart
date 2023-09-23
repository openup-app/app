import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/location/location_service.dart';
import 'package:openup/widgets/common.dart';

final _cameraPositionProvider = StateProvider<CameraPosition?>((ref) => null);

class MapDisplay extends ConsumerStatefulWidget {
  final List<RenderedItem> items;
  final RenderedItem? selectedItem;
  final ValueChanged<MapItem?> onSelectionChanged;
  final double itemAnimationSpeedMultiplier;
  final Location initialLocation;
  final ValueChanged<Location> onLocationChanged;
  final double obscuredRatio;
  final VoidCallback onShowRecordPanel;

  const MapDisplay({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onSelectionChanged,
    this.itemAnimationSpeedMultiplier = 1.0,
    required this.initialLocation,
    required this.onLocationChanged,
    this.obscuredRatio = 0.0,
    required this.onShowRecordPanel,
  }) : assert(itemAnimationSpeedMultiplier >= 0);

  @override
  ConsumerState<MapDisplay> createState() => MapDisplayState();
}

class MapDisplayState extends ConsumerState<MapDisplay> {
  maps.GoogleMapController? _mapController;
  LatLngBounds? _bounds;

  final _itemFrameIndexes = <RenderedItem, double>{};
  double _selectedItemFrameIndex = 0;
  bool _animatingItems = false;

  final _preferredTilt = 40.0;
  final _initialZoom = 13.9;

  @override
  void initState() {
    super.initState();
    ref.listenManual(userProvider.select((p) {
      return p.map(
        guest: (_) => null,
        signedIn: (signedIn) => signedIn.account.profile.latLongOverride,
      );
    }), (previous, next) {
      if (previous == null && next != null) {
        recenterMap(next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate new items
    final oldItemIds = oldWidget.items.map((r) => r.item.id).toList();
    final itemIds = widget.items.map((e) => e.item.id).toList();
    final addedItems = widget.items
        .where((item) => !oldItemIds.contains(item.item.id))
        .toList();
    final removedIds = oldWidget.items
        .map((i) => i.item.id)
        .where((id) => !itemIds.contains(id))
        .toList();
    _itemFrameIndexes
        .removeWhere((key, value) => removedIds.contains(key.item.id));
    final smallestNegativeFrameIndexOrZero =
        min(minBy(_itemFrameIndexes.values, (i) => i) ?? 0.0, 0.0);
    for (var i = 0; i < addedItems.length; i++) {
      _itemFrameIndexes[addedItems[i]] = smallestNegativeFrameIndexOrZero - i;
    }

    // Animate selected item
    final selectedItem = widget.selectedItem;
    final oldSelectedItem = oldWidget.selectedItem;
    final selectedItemChanged =
        selectedItem?.item.id != oldSelectedItem?.item.id;
    if (selectedItemChanged) {
      _selectedItemFrameIndex = 0;
    }

    if (addedItems.isNotEmpty || selectedItemChanged) {
      _animatingItems = true;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.selectedItem;
    return TickerBuilder(
      enabled: _animatingItems,
      builder: (context) {
        if (_animatingItems) {
          WidgetsBinding.instance.endOfFrame.then((_) {
            if (mounted) {
              _incrementFrames();
            }
          });
        }
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.initialLocation.latLong.latitude,
              widget.initialLocation.latLong.longitude,
            ),
            zoom: _initialZoom,
            tilt: _preferredTilt,
          ),
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: true,
          minMaxZoomPreference: const MinMaxZoomPreference(4, null),
          onMapCreated: _initMapController,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onCameraIdle: () {
            final position = ref.read(_cameraPositionProvider);
            final mapController = _mapController;
            if (mapController != null && position != null) {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: position.target,
                    bearing: position.bearing,
                    zoom: position.zoom,
                    tilt: _preferredTilt,
                  ),
                ),
              );
            }
            _onCameraMoved();
          },
          onCameraMove: (p) =>
              ref.read(_cameraPositionProvider.notifier).state = p,
          onTap: (_) => widget.onSelectionChanged(null),
          markers: _buildMapMarkers(selectedItem),
        );
      },
    );
  }

  Set<Marker> _buildMapMarkers(RenderedItem? selectedItem) {
    final markers = <Marker>{};

    for (final entry in _itemFrameIndexes.entries) {
      int frameIndex = entry.value.floor();
      if (frameIndex.isNegative) {
        continue;
      }

      final item = entry.key.item;
      final selected = item.id == selectedItem?.item.id;
      final Uint8List frame;
      final selectedFrames = widget.selectedItem?.frames;
      if (!selected || selectedFrames == null) {
        frame = entry.key.frames[frameIndex];
      } else {
        frame = selectedFrames[_selectedItemFrameIndex.floor()];
      }
      final favorite = item.favorite;

      final marker = Marker(
        markerId: MarkerId(item.id.toString()),
        anchor: const Offset(0.5, 0.5),
        zIndex: selected ? 10 : (favorite ? 5 : 0),
        consumeTapEvents: true,
        position: LatLng(
          item.latLong.latitude,
          item.latLong.longitude,
        ),
        onTap: () => widget.onSelectionChanged(item),
        icon: BitmapDescriptor.fromBytes(frame),
      );
      markers.add(marker);
    }
    return markers;
  }

  void _incrementFrames() {
    setState(() => _animatingItems = false);
    final speedMultiplier = widget.itemAnimationSpeedMultiplier;

    for (final entry in _itemFrameIndexes.entries) {
      final frameIndex = entry.value;
      final maxFrameIndex = entry.key.frames.length - 1;
      if (frameIndex < maxFrameIndex) {
        setState(() {
          _itemFrameIndexes[entry.key] = min(
            frameIndex + 1 * speedMultiplier,
            maxFrameIndex.toDouble(),
          );
          _animatingItems = true;
        });
      }
    }

    final selectedItem = widget.selectedItem;
    if (selectedItem != null) {
      final maxSelectedItemFrame = selectedItem.frames.length - 1;
      if (_selectedItemFrameIndex < maxSelectedItemFrame) {
        _selectedItemFrameIndex = min(
          _selectedItemFrameIndex + 1 * speedMultiplier,
          maxSelectedItemFrame.toDouble(),
        );
        setState(() => _animatingItems = true);
      }
    }
  }

  void _initMapController(GoogleMapController controller) async {
    controller.setMapStyle(_mapStyle());
    setState(() => _mapController = controller);
  }

  void _onCameraMoved() async {
    final bounds = await _mapController?.getVisibleRegion();
    final zoom = await _mapController?.getZoomLevel();
    if (bounds == null || zoom == null || !mounted) {
      return;
    }
    setState(() {
      _bounds = bounds;
    });

    final center = LatLong(
      latitude: (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      longitude: (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    final distance = greatCircleDistance(
      LatLong(
        latitude: bounds.northeast.latitude,
        longitude: bounds.northeast.longitude,
      ),
      LatLong(
        latitude: bounds.southwest.latitude,
        longitude: bounds.southwest.longitude,
      ),
    );
    widget.onLocationChanged(
      Location(
        latLong: center,
        radius: distance / 2,
      ),
    );
  }

  void recenterMap(LatLong latLong) {
    double targetLatitude = latLong.latitude;
    final bounds = _bounds;
    if (bounds != null &&
        widget.obscuredRatio != 0.0 &&
        widget.selectedItem != null) {
      final visibleLatitudeRange =
          (bounds.southwest.latitude - bounds.northeast.latitude).abs() *
              (1 - widget.obscuredRatio);
      targetLatitude = latLong.latitude - visibleLatitudeRange / 2;
    }
    final CameraPosition pos = CameraPosition(
      target: LatLng(targetLatitude, latLong.longitude),
      zoom: _initialZoom,
      tilt: _preferredTilt,
    );
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }
}

abstract class MapItem {
  int get id;
  LatLong get latLong;
  bool get favorite;
}

class RenderedItem {
  final MapItem item;
  final List<Uint8List> frames;

  RenderedItem({
    required this.item,
    required this.frames,
  });
}

String _mapStyle() {
  return jsonEncode(
    [
      {
        "featureType": "all",
        "elementType": "geometry",
        "stylers": [
          {"color": "#111111"}
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#757575"}
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.text.stroke",
        "stylers": [
          {"color": "#212121"}
        ]
      },
      {
        "featureType": "all",
        "elementType": "labels.icon",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {"color": "#757575"}
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#9e9e9e"}
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#bdbdbd"}
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "all",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#757575"},
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {"color": "#181818"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#616161"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {"color": "#1b1b1b"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {"color": "#000709"},
          {"saturation": "24"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#8a8a8a"}
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {"color": "#303030"}
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {"color": "#4e4e4e"}
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {"color": "#373737"}
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#616161"}
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#757575"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {"color": "#000818"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#3d3d3d"}
        ]
      }
    ],
  );
}
