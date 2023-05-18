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
import 'package:openup/widgets/profile_display.dart';

class DiscoverMap extends ConsumerStatefulWidget {
  final List<DiscoverProfile> profiles;
  final int profileIndex;
  final void Function(int index) onProfileChanged;
  final bool play;
  final VoidCallback onPlayPause;
  final VoidCallback showRecordPanel;

  const DiscoverMap({
    super.key,
    required this.profiles,
    required this.profileIndex,
    required this.onProfileChanged(int index),
    required this.play,
    required this.onPlayPause,
    required this.showRecordPanel,
  });

  @override
  ConsumerState<DiscoverMap> createState() => _DiscoverMapState();
}

class _DiscoverMapState extends ConsumerState<DiscoverMap> {
  maps.GoogleMapController? _googleMapController;
  final _mapMarkerImages = <String, Uint8List>{};
  int? _profileIndex;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant DiscoverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profileIndex != oldWidget.profileIndex) {
      setState(() => _profileIndex = widget.profileIndex);
      recenterMap(LocationStatus.value(
          widget.profiles[widget.profileIndex].location.latLong));
    }
  }

  @override
  void dispose() {
    _googleMapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileIndex = _profileIndex;
    final Profile? profile;
    if (profileIndex != null) {
      profile = widget.profiles[profileIndex].profile;
    } else {
      profile = null;
    }
    final initialLatLong =
        widget.profiles[widget.profileIndex].location.latLong;
    return Stack(
      children: [
        GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(initialLatLong.latitude, initialLatLong.longitude),
            zoom: 14.4746,
          ),
          onMapCreated: (controller) async {
            controller.setMapStyle(_nightMapStyle());
            setState(() => _googleMapController = controller);
            _updateImages();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          onTap: (_) => setState(() => _profileIndex = null),
          markers: {
            for (final profile in widget.profiles)
              Marker(
                markerId: MarkerId(profile.profile.uid),
                position: LatLng(
                  profile.location.latLong.latitude,
                  profile.location.latLong.longitude,
                ),
                onTap: () {
                  final index = widget.profiles.indexOf(profile);
                  if (_profileIndex == null && widget.profileIndex == index) {
                    setState(() => _profileIndex = widget.profileIndex);
                  } else {
                    widget.onProfileChanged(index);
                  }
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
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (profile != null)
                      _CircleButton(
                        onPressed: widget.showRecordPanel,
                        child: const Icon(
                          Icons.mic,
                          size: 26,
                          color: Color.fromRGBO(0xFF, 0x00, 0x00, 1.0),
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
                  ],
                ),
                const SizedBox(height: 16),
                if (profile != null)
                  _ProfileBar(
                    profile: profile,
                    play: widget.play,
                    onPlayPause: widget.onPlayPause,
                  ),
                const SizedBox(height: 12),
                const _LocationBar(),
                const SizedBox(height: 24),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
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
      zoom: 14.4746,
    );
    _googleMapController?.animateCamera(CameraUpdate.newCameraPosition(pos));
  }

  void _updateImages() async {
    setState(() => _mapMarkerImages.clear());
    final images = await _createMapMarkerImages(
        widget.profiles.map((p) => p.profile).toList());
    if (mounted) {
      setState(() {
        _mapMarkerImages.clear();
        _mapMarkerImages.addAll(images);
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

class _LocationBar extends StatelessWidget {
  const _LocationBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(54)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 10,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.location_pin,
            color: Colors.black,
          ),
          const SizedBox(width: 8),
          const Text(
            'Location Services',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ProfileBar extends StatelessWidget {
  final Profile profile;
  final bool play;
  final VoidCallback onPlayPause;

  const _ProfileBar({
    super.key,
    required this.profile,
    required this.play,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(66)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, 2),
            blurRadius: 10,
            color: Color.fromRGBO(0x00, 0x00, 0x00, 0.25),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 12),
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: Image.network(
              profile.photo,
              width: 63,
              height: 63,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    InfoIcon(),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '1 mutual friends',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                width: 2,
                color: const Color.fromRGBO(0xFF, 0xA8, 0x00, 1.0),
              ),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '14:39',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Color.fromRGBO(0x43, 0x43, 0x43, 1.0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: onPlayPause,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: play
                  ? const Icon(
                      Icons.pause,
                      size: 42,
                      color: Color.fromRGBO(0x43, 0x43, 0x43, 1.0),
                    )
                  : const Icon(
                      Icons.play_arrow,
                      size: 42,
                      color: Color.fromRGBO(0x43, 0x43, 0x43, 1.0),
                    ),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _CircleButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
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
