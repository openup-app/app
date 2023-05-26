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
  final DiscoverProfile? selectedProfile;
  final ValueChanged<int?> onProfileChanged;
  final Location initialLocation;
  final ValueChanged<Location> onLocationChanged;
  final VoidCallback showRecordPanel;

  const DiscoverMap({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.initialLocation,
    required this.onLocationChanged,
    required this.showRecordPanel,
  });

  @override
  ConsumerState<DiscoverMap> createState() => DiscoverMapState();
}

class DiscoverMapState extends ConsumerState<DiscoverMap>
    with TickerProviderStateMixin {
  maps.GoogleMapController? _mapController;
  double _zoomLevel = 14.4746;

  final _mapMarkerAnimations = <String, List<Uint8List>>{};

  static const _markerAppearDuration = Duration(milliseconds: 350);
  final _frameCount =
      ((_markerAppearDuration.inMilliseconds / 1000) * 60).floor();

  final _selectedMapMarkerAnimation = <Uint8List>[];
  late final _selectedAnimationController = AnimationController(
    vsync: this,
    duration: _markerAppearDuration,
  );

  late final _staggeredAnimationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  );

  final _profilesToAnimate = <DiscoverProfile>[];

  bool _locationOverridden = false;

  @override
  void initState() {
    super.initState();
    _staggeredAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _profilesToAnimate.clear());
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mapMarkerAnimations.isEmpty) {
      _staggeredAnimationController.stop();
      _renderMapMarkers(widget.profiles).then((mapping) {
        if (mounted) {
          if (!_staggeredAnimationController.isAnimating) {
            _staggeredAnimationController.forward(from: 0);
          }
          setState(() => _mapMarkerAnimations.addAll(mapping));
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate selected profile
    final selectedProfile = widget.selectedProfile;
    if (selectedProfile != null) {
      if (selectedProfile.profile.uid !=
          oldWidget.selectedProfile?.profile.uid) {
        setState(() {
          _locationOverridden = false;
          _selectedMapMarkerAnimation.clear();
        });

        _renderSelectedMapMarker(selectedProfile).then((frames) {
          if (mounted) {
            setState(() {
              _selectedMapMarkerAnimation
                ..clear()
                ..addAll(frames);
            });
            _selectedAnimationController.forward(from: 0);
            if (!_locationOverridden) {
              recenterMap(selectedProfile.location.latLong);
            }
          }
        });
      }
    }

    // Remove remove cached map markers of profiles that aren't in the widget
    final removeUids = <String>[];
    final newUids = widget.profiles.map((e) => e.profile.uid).toSet();
    for (final uid in _mapMarkerAnimations.keys) {
      if (!newUids.contains(uid)) {
        removeUids.add(uid);
      }
    }
    if (removeUids.isNotEmpty) {
      setState(() => _mapMarkerAnimations
          .removeWhere((key, value) => removeUids.contains(key)));
    }

    // Deselect if selected profile was removed
    if (selectedProfile != null &&
        removeUids.contains(selectedProfile.profile.uid)) {
      widget.onProfileChanged(null);
    }

    // Create and animate the newly added profile map markers
    final newProfiles = <DiscoverProfile>[];
    for (final profile in widget.profiles) {
      if (!_mapMarkerAnimations.containsKey(profile.profile.uid)) {
        newProfiles.add(profile);
      }
    }
    if (newProfiles.isNotEmpty) {
      _staggeredAnimationController.stop();
      _renderMapMarkers(newProfiles).then((mappings) {
        if (mounted) {
          if (!_staggeredAnimationController.isAnimating) {
            _profilesToAnimate.addAll(newProfiles);
            _staggeredAnimationController.forward(from: 0);
          }
          setState(() => _mapMarkerAnimations..addAll(mappings));
        }
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _selectedAnimationController.dispose();
    _staggeredAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProfile = widget.selectedProfile;
    return AnimatedBuilder(
      animation: _selectedAnimationController,
      builder: (context, child) {
        return AnimatedBuilder(
          animation: _staggeredAnimationController,
          builder: (context, child) {
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
              onCameraMoveStarted: () {
                if (_locationOverridden == false) {
                  setState(() => _locationOverridden = true);
                }
              },
              onCameraIdle: _onCameraMoved,
              onTap: (_) => widget.onProfileChanged(null),
              markers: _buildMapMarkers(selectedProfile),
            );
          },
        );
      },
    );
  }

  Set<Marker> _buildMapMarkers(DiscoverProfile? selectedProfile) {
    final selectedIndex =
        (_selectedAnimationController.value * (_frameCount - 1)).toInt();

    final set = <Marker>{};
    for (final profile in widget.profiles) {
      int appearIndex = _frameCount - 1;
      final indexInAnimationList = _profilesToAnimate.indexOf(profile);
      if (indexInAnimationList != -1) {
        final ratio = indexInAnimationList / _profilesToAnimate.length;
        final durationNorm = _frameCount / 60;
        final staggeredAnimation = CurvedAnimation(
          parent: _staggeredAnimationController,
          curve: Interval(
            durationNorm * ratio,
            durationNorm * ratio + durationNorm,
          ),
        );
        appearIndex = (staggeredAnimation.value * (_frameCount - 1)).toInt();
      }

      final hasGeneratedMarker =
          _mapMarkerAnimations[profile.profile.uid] != null;
      if (hasGeneratedMarker) {
        final marker = Marker(
          markerId: MarkerId(profile.profile.uid),
          anchor: const Offset(0.5, 0.5),
          zIndex:
              profile.profile.uid == selectedProfile?.profile.uid ? 1.0 : 0.0,
          position: LatLng(
            profile.location.latLong.latitude,
            profile.location.latLong.longitude,
          ),
          onTap: () {
            final index = widget.profiles.indexOf(profile);
            widget.onProfileChanged(index);
          },
          icon: profile != selectedProfile
              ? BitmapDescriptor.fromBytes(
                  _mapMarkerAnimations[profile.profile.uid]![appearIndex])
              : (selectedIndex >= _selectedMapMarkerAnimation.length
                  ? BitmapDescriptor.fromBytes(_mapMarkerAnimations[
                      profile.profile.uid]![_frameCount - 1])
                  : BitmapDescriptor.fromBytes(
                      _selectedMapMarkerAnimation[selectedIndex])),
        );
        set.add(marker);
      }
    }
    return set;
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

  void recenterMap(LatLong latLong) {
    final CameraPosition pos = CameraPosition(
      target: LatLng(latLong.latitude, latLong.longitude),
      zoom: _zoomLevel,
    );
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  Future<Map<String, List<Uint8List>>> _renderMapMarkers(
    List<DiscoverProfile> profiles,
  ) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final mappings = <String, List<Uint8List>>{};
    for (final profile in profiles) {
      final frames = <Uint8List>[];
      for (var i = 0; i < _frameCount; i++) {
        final t = i / (_frameCount - 1);
        final animation = CurveTween(curve: Curves.bounceOut)
            .animate(AlwaysStoppedAnimation(t));
        final image =
            await _renderMapMarkerFrame(profile, pixelRatio, animation);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        frames.add(bytes!.buffer.asUint8List());
      }
      mappings[profile.profile.uid] = frames;
    }
    return mappings;
  }

  Future<ui.Image> _renderMapMarkerFrame(
    DiscoverProfile profile,
    double pixelRatio,
    Animation<double> animation,
  ) async {
    final textPainter = _createTextPainter(
      text: profile.profile.name,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
    final metrics = textPainter.computeLineMetrics()[0];

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    final textWidth = metrics.width;
    const horizontalPadding = 8.0;
    const verticalPadding = 20.0;
    const photoSize = 36.0;
    final width = photoSize + textWidth + horizontalPadding + 18;
    const height = photoSize + verticalPadding;

    final scaleAnimation = Matrix4.identity()
      ..translate(width / 2, height / 2)
      ..scale(animation.value)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    final photo = await _fetchImage(
      NetworkImage(profile.profile.photo),
      size: const Size.square(photoSize),
      pixelRatio: pixelRatio,
    );
    _paintProfilePill(
      canvas: canvas,
      textPainter: textPainter,
      metrics: metrics,
      photo: photo,
      backgroundColor: Colors.white,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      width: width,
      height: height,
    );

    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width).toInt(),
      (pixelRatio * height).toInt(),
    );
  }

  Future<List<Uint8List>> _renderSelectedMapMarker(
    DiscoverProfile profile,
  ) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final frames = <Uint8List>[];
    for (var i = 0; i < _frameCount; i++) {
      final t = i / (_frameCount - 1);
      final animation = CurveTween(curve: Curves.easeOutQuart)
          .animate(AlwaysStoppedAnimation(t));
      final image =
          await _renderSelectedMapMarkerFrame(profile, pixelRatio, animation);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      frames.add(bytes!.buffer.asUint8List());
    }
    return frames;
  }

  Future<ui.Image> _renderSelectedMapMarkerFrame(
    DiscoverProfile profile,
    double pixelRatio,
    Animation<double> animation,
  ) async {
    final textPainter = _createTextPainter(
      text: profile.profile.name,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: ColorTween(begin: Colors.black, end: Colors.white)
            .evaluate(animation),
      ),
    );
    final metrics = textPainter.computeLineMetrics()[0];

    final pictureRecorder = ui.PictureRecorder();
    final canvas = ui.Canvas(pictureRecorder);

    final textWidth = metrics.width;
    const horizontalPadding = 8.0;
    const verticalPadding = 20.0;
    const photoSize = 36.0;
    final width = photoSize + textWidth + horizontalPadding + 18;
    const height = photoSize + verticalPadding;

    final scale = 1.0 + 0.33 * animation.value;

    final scaleAnimation = Matrix4.identity()
      ..translate(width * scale / 2, height * scale / 2)
      ..scale(scale)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    final photo = await _fetchImage(
      NetworkImage(profile.profile.photo),
      size: const Size.square(photoSize),
      pixelRatio: pixelRatio,
    );
    _paintProfilePill(
      canvas: canvas,
      textPainter: textPainter,
      metrics: metrics,
      photo: photo,
      backgroundColor: ColorTween(
        begin: Colors.white,
        end: const Color.fromRGBO(0x0A, 0x7B, 0xFF, 1.0),
      ).evaluate(animation)!,
      profileOutlineColor: ColorTween(
        begin: null,
        end: Colors.white,
      ).evaluate(animation),
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
      width: width,
      height: height,
    );

    final picture = pictureRecorder.endRecording();
    return picture.toImage(
      (pixelRatio * width * scale).toInt(),
      (pixelRatio * height * scale).toInt(),
    );
  }

  void _paintProfilePill({
    required Canvas canvas,
    required TextPainter textPainter,
    required ui.LineMetrics metrics,
    required ui.Image photo,
    required Color backgroundColor,
    Color? profileOutlineColor,
    required double horizontalPadding,
    required double verticalPadding,
    required double width,
    required double height,
  }) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(width / 2, height / 2),
        width: width - horizontalPadding,
        height: height - verticalPadding,
      ),
      Radius.circular((height - verticalPadding) / 2),
    );
    canvas.drawShadow(
      Path()..addRRect(rrect),
      const Color.fromRGBO(0x00, 0x00, 0x00, 1.0),
      8,
      false,
    );
    canvas.drawRRect(rrect, Paint()..color = backgroundColor);
    const textLeftPadding = 44.0;
    final textTopPadding = (height - metrics.height) / 2;
    textPainter.paint(
      canvas,
      Offset(textLeftPadding, textTopPadding),
    );

    final photoCenter = Offset((height - verticalPadding) / 2 + 4, height / 2);
    final photoSize = height - verticalPadding - 7.5;
    if (profileOutlineColor != null) {
      canvas.drawCircle(
        photoCenter,
        photoSize / 2 + 1.5,
        Paint()..color = profileOutlineColor,
      );
    }

    canvas.clipPath(
      Path()
        ..addOval(Rect.fromCenter(
          center: photoCenter,
          width: photoSize,
          height: photoSize,
        )),
    );
    canvas.drawImageRect(
      photo,
      Offset.zero & Size(photo.width.toDouble(), photo.height.toDouble()),
      Rect.fromCenter(
        center: photoCenter,
        width: photoSize,
        height: photoSize,
      ),
      Paint()..color = Colors.white,
    );
  }

  TextPainter _createTextPainter({
    required String text,
    required TextStyle style,
    double maxWidth = 200,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: style,
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: maxWidth);
    return textPainter;
  }
}

Future<ui.Image> _fetchImage(
  ImageProvider provider, {
  required Size size,
  required double pixelRatio,
}) {
  final completer = Completer<ui.Image>();
  final listener = ImageStreamListener((imageInfo, _) {
    completer.complete(imageInfo.image);
  }, onError: (error, stackTrace) {
    completer.completeError(error, stackTrace);
  });
  provider
      .resolve(ImageConfiguration(size: size, devicePixelRatio: pixelRatio))
      .addListener(listener);
  return completer.future;
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
