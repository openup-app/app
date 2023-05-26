import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/util/location_service.dart';

class DiscoverMap extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final int? profileIndex;
  final ValueChanged<int?> onProfileChanged;
  final Location initialLocation;
  final ValueChanged<Location> onLocationChanged;
  final VoidCallback showRecordPanel;

  const DiscoverMap({
    super.key,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileChanged,
    required this.initialLocation,
    required this.onLocationChanged,
    required this.showRecordPanel,
  });

  @override
  ConsumerState<DiscoverMap> createState() => DiscoverMapState();
}

class DiscoverMapState extends ConsumerState<DiscoverMap>
    with SingleTickerProviderStateMixin {
  maps.GoogleMapController? _mapController;
  double _zoomLevel = 14.4746;
  final _mapMarkerAnimations = <String, List<Uint8List>>{};
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final _frameCount =
      ((_animationController.duration!.inMilliseconds / 1000) * 60).floor();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapMarkerAnimations.isEmpty) {
      _createMapMarkers(widget.profiles).then((mapping) {
        if (mounted) {
          if (!_animationController.isAnimating) {
            _animationController.forward(from: 0);
          }
          setState(() => _mapMarkerAnimations.addAll(mapping));
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final profileIndex = widget.profileIndex;
    if (profileIndex != oldWidget.profileIndex && profileIndex != null) {
      recenterMap(
          LocationStatus.value(widget.profiles[profileIndex].location.latLong));
    }

    final removeUids = <String>[];
    final newUids = widget.profiles.map((e) => e.profile.uid).toSet();
    for (final uid in _mapMarkerAnimations.keys) {
      if (!newUids.contains(uid)) {
        removeUids.add(uid);
      }
    }
    setState(() => _mapMarkerAnimations
        .removeWhere((key, value) => removeUids.contains(key)));

    final missingProfiles = <DiscoverProfile>[];
    for (final profile in widget.profiles) {
      if (!_mapMarkerAnimations.containsKey(profile.profile.uid)) {
        missingProfiles.add(profile);
      }
    }
    if (missingProfiles.isNotEmpty) {
      _createMapMarkers(missingProfiles).then((mappings) {
        if (mounted) {
          if (!_animationController.isAnimating) {
            _animationController.forward(from: 0);
          }
          setState(() => _mapMarkerAnimations
            ..clear()
            ..addAll(mappings));
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final index = (_animationController.value * (_frameCount - 1)).toInt();
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.initialLocation.latLong.latitude,
              widget.initialLocation.latLong.longitude,
            ),
            zoom: 14.4746,
          ),
          onMapCreated: _initMapController,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onCameraIdle: _onCameraMoved,
          onTap: (_) => widget.onProfileChanged(null),
          markers: {
            for (final profile in widget.profiles)
              if (_mapMarkerAnimations[profile.profile.uid] != null)
                Marker(
                  markerId: MarkerId(profile.profile.uid),
                  position: LatLng(
                    profile.location.latLong.latitude,
                    profile.location.latLong.longitude,
                  ),
                  onTap: () {
                    final index = widget.profiles.indexOf(profile);
                    widget.onProfileChanged(index);
                  },
                  icon: _mapMarkerAnimations[profile.profile.uid] == null
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.fromBytes(
                          _mapMarkerAnimations[profile.profile.uid]![index]),
                ),
          },
        );
      },
    );
  }

  void _initMapController(GoogleMapController controller) async {
    controller.setMapStyle(_nightMapStyle());
    setState(() => _mapController = controller);
  }

  void _onCameraMoved() async {
    final bounds = await _mapController?.getVisibleRegion();
    final zoom = await _mapController?.getZoomLevel();
    if (bounds == null || zoom == null) {
      return;
    }

    final center = LatLong(
      latitude: (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      longitude: (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
    final distance = greatCircleDistance(
      center,
      LatLong(
        latitude: bounds.northeast.latitude,
        longitude: bounds.northeast.longitude,
      ),
    );
    widget.onLocationChanged(
      Location(
        latLong: center,
        radius: distance,
      ),
    );
    setState(() => _zoomLevel = zoom);
  }

  void recenterMap(LocationStatus? status) {
    final latLong = status?.map(
      value: (value) => value.latLong,
      denied: (_) => null,
      failure: (_) => null,
    );
    const googleplexLatLong = LatLng(
      37.42796133580664,
      -122.085749655962,
    );
    final CameraPosition pos = CameraPosition(
      target: latLong != null
          ? LatLng(latLong.latitude, latLong.longitude)
          : googleplexLatLong,
      zoom: _zoomLevel,
    );
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  Future<Map<String, List<Uint8List>>> _createMapMarkers(
    List<DiscoverProfile> profiles,
  ) async {
    _animationController.stop();
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final mappings = <String, List<Uint8List>>{};
    final tween = CurveTween(curve: Curves.easeOutQuart);
    for (final profile in profiles) {
      final frames = <Uint8List>[];
      for (var i = 0; i < _frameCount; i++) {
        final t = i / _frameCount;
        final image = await _createMapMarkerFrame(
            profile, pixelRatio, tween.evaluate(AlwaysStoppedAnimation(t)));
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        frames.add(bytes!.buffer.asUint8List());
      }
      mappings[profile.profile.uid] = frames;
    }
    return mappings;
  }

  Future<ui.Image> _fetchImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final listener = ImageStreamListener((imageInfo, _) {
      completer.complete(imageInfo.image);
    }, onError: (error, stackTrace) {
      completer.completeError(error, stackTrace);
    });
    provider.resolve(ImageConfiguration.empty).addListener(listener);
    return completer.future;
  }

  Future<ui.Image> _createMapMarkerFrame(
    DiscoverProfile profile,
    double pixelRatio,
    double t,
  ) async {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1));
    builder.pushStyle(ui.TextStyle(color: Colors.black));
    builder.addText(profile.profile.name);
    final image = await _fetchImage(NetworkImage(profile.profile.photo));

    final textPainter = TextPainter(
      text: TextSpan(
        text: profile.profile.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: 200);
    final metrics = textPainter.computeLineMetrics();

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);
    const textLeftPadding = 2.0;
    const textRightPadding = 12.0;
    const textTopPadding = 10.0;
    final metric = metrics[0];

    final width =
        2 + 34 + 2 + textLeftPadding + metric.width + textRightPadding;
    const height = 36.0;

    final scaleAnimation = Matrix4.identity()
      ..translate(width / 2, height / 2)
      ..scale(t)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        const Radius.circular(38),
      ),
    );
    canvas.drawPaint(Paint()..color = Colors.white);

    textPainter.paint(
      canvas,
      const Offset(2 + 34 + 2 + textLeftPadding, textTopPadding),
    );

    canvas.clipPath(Path()..addOval(const Rect.fromLTWH(2, 2, 32, 32)));
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(2, 2, 34, 34),
      Paint()..color = Colors.white,
    );
    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width).toInt(),
      (pixelRatio * height).toInt(),
    );
  }
}

String _nightMapStyle() {
  return jsonEncode(
    [
      {
        'elementType': 'geometry',
        'stylers': [
          {'color': '#242f3e'}
        ]
      },
      {
        'elementType': 'labels.text.stroke',
        'stylers': [
          {'color': '#242f3e'}
        ]
      },
      {
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#746855'}
        ]
      },
      {
        'featureType': 'administrative.locality',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'poi',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'poi.park',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#263c3f'}
        ],
      },
      {
        'featureType': 'poi.park',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#6b9a76'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#38414e'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'geometry.stroke',
        'stylers': [
          {'color': '#212a37'}
        ],
      },
      {
        'featureType': 'road',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#9ca5b3'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#746855'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'geometry.stroke',
        'stylers': [
          {'color': '#1f2835'}
        ],
      },
      {
        'featureType': 'road.highway',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#f3d19c'}
        ],
      },
      {
        'featureType': 'transit',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#2f3948'}
        ],
      },
      {
        'featureType': 'transit.station',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#d59563'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'geometry',
        'stylers': [
          {'color': '#17263c'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'labels.text.fill',
        'stylers': [
          {'color': '#515c6d'}
        ],
      },
      {
        'featureType': 'water',
        'elementType': 'labels.text.stroke',
        'stylers': [
          {'color': '#17263c'}
        ],
      },
    ],
  );
}
