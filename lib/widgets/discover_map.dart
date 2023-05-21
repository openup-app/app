import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/button.dart';

class DiscoverMap extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final int? profileIndex;
  final ValueChanged<int?> onProfileChanged;
  final WidgetBuilder bottomBuilder;
  final Location initialLocation;
  final ValueChanged<Location> onLocationChanged;
  final VoidCallback showRecordPanel;

  const DiscoverMap({
    super.key,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileChanged,
    required this.bottomBuilder,
    required this.initialLocation,
    required this.onLocationChanged,
    required this.showRecordPanel,
  });

  @override
  ConsumerState<DiscoverMap> createState() => _DiscoverMapState();
}

class _DiscoverMapState extends ConsumerState<DiscoverMap> {
  maps.GoogleMapController? _mapController;
  double _zoomLevel = 14.4746;
  final _mapMarkerImages = <String, Uint8List>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapMarkerImages.isEmpty) {
      _createAllMapMarkerImages();
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

    final missingProfiles = <Profile>[];
    for (final profile in widget.profiles) {
      if (!_mapMarkerImages.containsKey(profile.profile.uid)) {
        missingProfiles.add(profile.profile);
      }
    }
    if (missingProfiles.isNotEmpty) {
      _createMapMarkerImages(missingProfiles).then((mappings) {
        if (mounted) {
          setState(() => _mapMarkerImages.addAll(mappings));
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Profile? profile;
    final profileIndex = widget.profileIndex;
    if (profileIndex != null && profileIndex < widget.profiles.length) {
      profile = widget.profiles[profileIndex].profile;
    } else {
      profile = null;
    }

    return Stack(
      children: [
        GoogleMap(
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
              if (_mapMarkerImages[profile.profile.uid] != null)
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
                  icon: _mapMarkerImages[profile.profile.uid] == null
                      ? BitmapDescriptor.defaultMarker
                      : BitmapDescriptor.fromBytes(
                          _mapMarkerImages[profile.profile.uid]!),
                ),
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (profile != null)
                    _CircleButton(
                      color: const Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
                      onPressed: () {},
                      child: const Icon(
                        Icons.circle,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 8),
                  _CircleButton(
                    onPressed: () => recenterMap(ref.read(locationProvider)),
                    child: const Icon(
                      CupertinoIcons.location_fill,
                      size: 26,
                      color: Color.fromRGBO(0x22, 0x53, 0xFF, 1.0),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutQuart,
                child: widget.bottomBuilder(context),
              ),
            ],
          ),
        ),
      ],
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

  void _createAllMapMarkerImages() async {
    final mapping = await _createMapMarkerImages(
        widget.profiles.map((p) => p.profile).toList());
    if (mounted) {
      setState(() {
        _mapMarkerImages.clear();
        _mapMarkerImages.addAll(mapping);
      });
    }
  }

  Future<Map<String, Uint8List>> _createMapMarkerImages(
    List<Profile> profiles,
  ) async {
    final images = <Uint8List>[];
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    for (final profile in profiles) {
      final image = await _createMapMarkerImage(profile, pixelRatio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      images.add(bytes!.buffer.asUint8List());
      image.dispose();
    }
    final mapping = <String, Uint8List>{};
    for (var i = 0; i < profiles.length; i++) {
      mapping[profiles[i].uid] = images[i];
    }
    return mapping;
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

  Future<ui.Image> _createMapMarkerImage(
      Profile profile, double pixelRatio) async {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1));
    builder.pushStyle(ui.TextStyle(color: Colors.black));
    builder.addText(profile.name);
    final image = await _fetchImage(NetworkImage(profile.photo));

    final textPainter = TextPainter(
      text: TextSpan(
        text: profile.name,
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

    canvas.scale(pixelRatio);

    final width =
        2 + 34 + 2 + textLeftPadding + metric.width + textRightPadding;
    const height = 36.0;

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

class _CircleButton extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback onPressed;

  const _CircleButton({
    super.key,
    required this.onPressed,
    this.color = Colors.white,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 2),
              blurRadius: 10,
              color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
            )
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
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
