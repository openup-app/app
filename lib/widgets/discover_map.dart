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
import 'package:openup/widgets/map_marker_rendering.dart';

class DiscoverMap extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final DiscoverProfile? selectedProfile;
  final ValueChanged<DiscoverProfile?> onProfileChanged;
  final Location initialLocation;
  final ValueChanged<Location> onLocationChanged;
  final double obscuredRatio;
  final VoidCallback showRecordPanel;
  final void Function(MarkerRenderStatus status) onMarkerRenderStatus;

  const DiscoverMap({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileChanged,
    required this.initialLocation,
    required this.onLocationChanged,
    this.obscuredRatio = 0.0,
    required this.showRecordPanel,
    required this.onMarkerRenderStatus,
  });

  @override
  ConsumerState<DiscoverMap> createState() => DiscoverMapState();
}

class DiscoverMapState extends ConsumerState<DiscoverMap>
    with TickerProviderStateMixin {
  maps.GoogleMapController? _mapController;
  double _zoomLevel = 14.4746;
  LatLngBounds? _bounds;

  final _onscreenMarkers = <RenderedProfile>[];

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

  final _markersReadyToAnimate = <DiscoverProfile>{};
  final _markersAnimating = <DiscoverProfile>[];

  bool _locationOverridden = false;

  late final MarkerRenderingStateMachine _markerRenderStateMachine;

  @override
  void initState() {
    super.initState();
    _staggeredAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _markersAnimating.clear());
        _maybeStartNextStagger();
      }
    });

    _markerRenderStateMachine = MarkerRenderingStateMachine(
      onRenderStart: (profiles) {
        if (!mounted) {
          return Future.value([]);
        }
        widget.onMarkerRenderStatus(MarkerRenderStatus.rendering);
        return _renderMapMarkers(profiles);
      },
      onRenderEnd: _onRenderEnd,
    );
  }

  void _onRenderEnd(List<RenderedProfile> renders) {
    if (!mounted) {
      return;
    }

    final uids = renders.map((e) => e.profile.profile.uid).toList();
    final onscreenUids = _onscreenMarkers.map((r) => r.profile.profile.uid);
    setState(() {
      final profiles =
          widget.profiles.where((p) => uids.contains(p.profile.uid));
      _markersReadyToAnimate
          .addAll(profiles.where((p) => !onscreenUids.contains(p.profile.uid)));
      _onscreenMarkers.addAll(renders);
    });
    _maybeStartNextStagger();
    widget.onMarkerRenderStatus(MarkerRenderStatus.ready);
  }

  void _maybeStartNextStagger() {
    if (_markersReadyToAnimate.isNotEmpty) {
      setState(() {
        _markersAnimating.addAll(_markersReadyToAnimate.toList());
        _markersReadyToAnimate.clear();
      });
      _staggeredAnimationController.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(covariant DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate selected profile
    final selectedProfile = widget.selectedProfile;
    final oldSelectedProfile = oldWidget.selectedProfile;
    if (selectedProfile != null) {
      if (selectedProfile.profile.uid != oldSelectedProfile?.profile.uid) {
        setState(() {
          _locationOverridden = false;
          _selectedMapMarkerAnimation.clear();
        });

        // Re-render selected
        _renderMapMarker(profile: selectedProfile, selected: true)
            .then((frames) {
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
      } else if (selectedProfile.profile.uid ==
              oldSelectedProfile?.profile.uid &&
          selectedProfile.favorite != oldSelectedProfile?.favorite) {
        // Re-render selected
        // Update the favorite icon
        final unselectedFramesFuture =
            _renderMapMarker(profile: selectedProfile, selected: false);
        final selectedFramesFuture =
            _renderMapMarker(profile: selectedProfile, selected: true);
        Future.wait([unselectedFramesFuture, selectedFramesFuture])
            .then((results) {
          if (mounted) {
            final index = _onscreenMarkers.indexWhere(
                (r) => r.profile.profile.uid == selectedProfile.profile.uid);
            if (index != -1) {
              final r = _onscreenMarkers[index];
              setState(() {
                _onscreenMarkers[index] = RenderedProfile(
                  profile: r.profile,
                  frames: results[0],
                );
              });
            }
            setState(() {
              _selectedMapMarkerAnimation
                ..clear()
                ..addAll(results[1]);
            });
          }
        });
      }
    }

    // Deselect if selected profile was removed
    if (selectedProfile != null &&
        !widget.profiles
            .map((e) => e.profile.uid)
            .contains(selectedProfile.profile.uid)) {
      WidgetsBinding.instance.endOfFrame.then((_) {
        if (mounted) {
          widget.onProfileChanged(null);
        }
      });
    }

    _markerRenderStateMachine.profilesUpdated(profiles: widget.profiles);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _selectedAnimationController.dispose();
    _staggeredAnimationController.dispose();
    _markerRenderStateMachine.dispose();
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
                zoom: 10,
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

  void resetMarkers() {
    _markerRenderStateMachine.reset();
  }

  Set<Marker> _buildMapMarkers(DiscoverProfile? selectedProfile) {
    final set = <Marker>{};

    final animationQueue = _markersAnimating.map((e) => e.profile.uid).toList();
    for (final rendered in _onscreenMarkers) {
      final profile = rendered.profile;
      int frameIndex = _frameCount - 1;

      // Some profiles may be animating in
      final staggerIndex = animationQueue.indexOf(profile.profile.uid);
      if (staggerIndex != -1) {
        final ratio =
            (staggerIndex / (animationQueue.length - 1)).clamp(0.0, 1.0);
        final durationNormalized = _frameCount / 60;
        final staggeredAnimation = CurvedAnimation(
          parent: _staggeredAnimationController,
          curve: Interval(
            durationNormalized * ratio,
            durationNormalized * ratio + durationNormalized,
          ),
        );
        frameIndex = (staggeredAnimation.value * (_frameCount - 1)).toInt();
      }

      Uint8List? frame = rendered.frames.elementAt(frameIndex);
      final favorite = profile.favorite;
      final selected = profile.profile.uid == selectedProfile?.profile.uid;
      if (selected) {
        final selectedFrameIndex =
            (_selectedAnimationController.value * (_frameCount - 1)).toInt();
        if (selectedFrameIndex < _selectedMapMarkerAnimation.length) {
          frame = _selectedMapMarkerAnimation[selectedFrameIndex];
        }
      }

      final marker = Marker(
        markerId: MarkerId(profile.profile.uid),
        anchor: const Offset(0.5, 0.5),
        zIndex: selected ? 10 : (favorite ? 5 : 0),
        position: LatLng(
          profile.location.latLong.latitude,
          profile.location.latLong.longitude,
        ),
        onTap: () => widget.onProfileChanged(profile),
        icon: BitmapDescriptor.fromBytes(frame),
      );
      set.add(marker);
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
    if (bounds == null || zoom == null || !mounted) {
      return;
    }
    setState(() {
      _bounds = bounds;
      _zoomLevel = zoom;
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

    _removeOffscreenProfiles(bounds);
    setState(() => _zoomLevel = zoom);
  }

  void _removeOffscreenProfiles(LatLngBounds bounds) {
    final removeUids = <String>[];
    final longitudeSpan =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    final latitudeSpan =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    final longitudePadding = longitudeSpan * 0.15;
    final latitudePadding = latitudeSpan * 0.15;
    for (final render in _onscreenMarkers) {
      final latLong = render.profile.location.latLong;
      if ((latLong.latitude > bounds.northeast.latitude + latitudePadding) ||
          (latLong.latitude < bounds.southwest.latitude - latitudePadding) ||
          (latLong.longitude > bounds.northeast.longitude + longitudePadding) ||
          (latLong.longitude < bounds.southwest.longitude - longitudePadding)) {
        removeUids.add(render.profile.profile.uid);
      }
    }
    // TODO: Remove them from state machine cache
    _onscreenMarkers
        .removeWhere((r) => removeUids.contains(r.profile.profile.uid));
  }

  void recenterMap(LatLong latLong) {
    double targetLatitude = latLong.latitude;
    final bounds = _bounds;
    if (bounds != null && widget.obscuredRatio != 0.0) {
      final visibleLatitudeRange =
          (bounds.southwest.latitude - bounds.northeast.latitude).abs() *
              (1 - widget.obscuredRatio);
      targetLatitude = latLong.latitude - visibleLatitudeRange / 2;
    }
    final CameraPosition pos = CameraPosition(
      target: LatLng(targetLatitude, latLong.longitude),
      zoom: _zoomLevel,
    );
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  Future<List<RenderedProfile>> _renderMapMarkers(
      List<DiscoverProfile> profiles) async {
    final rendered = <RenderedProfile>[];
    for (final profile in profiles) {
      final frames = await _renderMapMarker(
        profile: profile,
        selected: false,
      );
      rendered.add(RenderedProfile(profile: profile, frames: frames));
    }
    return rendered;
  }

  Future<List<Uint8List>> _renderMapMarker({
    required DiscoverProfile profile,
    required bool selected,
  }) async {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final frames = <Uint8List>[];
    for (var i = 0; i < _frameCount; i++) {
      final t = i / (_frameCount - 1);
      final animation =
          CurveTween(curve: selected ? Curves.easeOutQuart : Curves.bounceOut)
              .animate(AlwaysStoppedAnimation(t));
      final image = selected
          ? await _renderSelectedMapMarkerFrame(profile, pixelRatio, animation)
          : await _renderMapMarkerFrame(profile, pixelRatio, animation);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      frames.add(bytes!.buffer.asUint8List());
    }
    return frames;
  }

  Future<ui.Image> _renderMapMarkerFrame(
    DiscoverProfile profile,
    double pixelRatio,
    Animation<double> animation,
  ) async {
    final textPainter = _createTextPainter(
      text: profile.profile.name,
      style: const TextStyle(
        fontSize: 10,
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
    const photoSize = 24.0;
    final width = photoSize + 4 + textWidth + horizontalPadding + 8;
    const height = photoSize + 4 + verticalPadding;

    final scaleAnimation = Matrix4.identity()
      ..translate(width / 2, height / 2)
      ..scale(animation.value)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    const icon = Icons.favorite;
    final favoriteIconPainter = !profile.favorite
        ? null
        : _createTextPainter(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 20,
              color: const Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
              fontFamily: icon.fontFamily,
            ),
          );

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
      favoriteIconPainter: favoriteIconPainter,
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
    final width = photoSize + textWidth + horizontalPadding + 8;
    const height = photoSize + verticalPadding;

    final scale = 1.0 + 0.33 * animation.value;

    final scaleAnimation = Matrix4.identity()
      ..translate(width * scale / 2, height * scale / 2)
      ..scale(scale)
      ..translate(-width / 2, -height / 2);
    canvas.scale(pixelRatio);
    canvas.transform(scaleAnimation.storage);

    const icon = Icons.favorite;
    final favoriteIconPainter = !profile.favorite
        ? null
        : _createTextPainter(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 20,
              color: const Color.fromRGBO(0xFF, 0x4F, 0x4F, 1.0),
              fontFamily: icon.fontFamily,
            ),
          );

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
      favoriteIconPainter: favoriteIconPainter,
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
    required TextPainter? favoriteIconPainter,
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
      const Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
      6,
      false,
    );

    final extraPhotoPadding = profileOutlineColor == null ? 0 : 2;
    final photoSize = height - verticalPadding - 7 - extraPhotoPadding;
    final photoCenter = Offset(
      horizontalPadding / 2 + 3 + extraPhotoPadding + photoSize / 2,
      height / 2,
    );

    canvas.drawRRect(rrect, Paint()..color = backgroundColor);
    final textLeftPadding = photoCenter.dx + photoSize / 2 + 4;
    final textTopPadding = (height - metrics.height) / 2;
    textPainter.paint(
      canvas,
      Offset(textLeftPadding, textTopPadding),
    );

    final iconMetrics = favoriteIconPainter?.computeLineMetrics()[0];
    if (favoriteIconPainter != null && iconMetrics != null) {
      favoriteIconPainter.paint(
        canvas,
        Offset(
          width - horizontalPadding / 2 - iconMetrics.width * 0.75,
          verticalPadding / 2 - iconMetrics.height * 0.3,
        ),
      );
    }

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

class RenderedProfile {
  final DiscoverProfile profile;
  final List<Uint8List> frames;

  RenderedProfile({
    required this.profile,
    required this.frames,
  });
}

enum MarkerRenderStatus { ready, rendering }

String _nightMapStyle() {
  return jsonEncode(
    [
      {
        "featureType": "poi",
        "elementType": "all",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.attraction",
        "elementType": "all",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "labels.text",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry.stroke",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "geometry.stroke",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      }
    ],
  );
}
