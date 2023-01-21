import 'package:async/async.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Chip;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/platform/just_audio_audio_player.dart';
import 'package:openup/util/location_service.dart';
import 'package:openup/widgets/back_button.dart';
import 'package:openup/widgets/carousel.dart';
import 'package:openup/widgets/common.dart';
import 'package:openup/widgets/profile_display.dart';
import 'package:permission_handler/permission_handler.dart';

class DiscoverPage extends ConsumerStatefulWidget {
  final ScrollToDiscoverTopNotifier scrollToTopNotifier;
  final GlobalKey<CarouselState> carouselKey;

  const DiscoverPage({
    Key? key,
    required this.scrollToTopNotifier,
    required this.carouselKey,
  }) : super(key: key);

  @override
  ConsumerState<DiscoverPage> createState() => DiscoverPageState();
}

class DiscoverPageState extends ConsumerState<DiscoverPage> {
  bool _loading = false;
  bool _hasLocation = false;

  CancelableOperation<Either<ApiError, DiscoverResults>>? _discoverOperation;
  final _profiles = <Profile>[];
  double _nextMinRadius = 0.0;
  int _nextPage = 0;

  int _currentProfileIndex = 0;
  Topic? _selectedTopic;
  final _invitedUsers = <String>{};

  final _pageListener = ValueNotifier<double>(1);
  final _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _fetchPageOfProfiles().then((_) {
      _maybeRequestNotification();
    });

    _pageController.addListener(() {
      final page = _pageController.page ?? 1;
      _pageListener.value = page;
      final oldIndex = _currentProfileIndex;
      final index = _pageController.page?.round() ?? _currentProfileIndex;
      final scrollingForward = index > oldIndex;
      if (_currentProfileIndex != index) {
        _precacheImageAndDepth(_profiles, from: index + 1, count: 2);
        setState(() => _currentProfileIndex = index);
        if (index > _profiles.length - 4 && !_loading && scrollingForward) {
          _fetchPageOfProfiles();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImageAndDepth(_profiles, from: 1, count: 2);
  }

  void _precacheImageAndDepth(
    List<Profile> profiles, {
    required int from,
    required int count,
  }) {
    profiles.skip(from).take(count).forEach((profile) {
      profile.gallery.forEach((photo) {
        precacheImage(NetworkImage(photo), context);
        precacheImage(NetworkImage('${photo}_depth'), context);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  Future<void> _maybeRequestNotification() async {
    final status = await Permission.notification.status;
    if (!(status.isGranted || status.isLimited)) {
      await Permission.notification.request();
    }
  }

  Future<bool> _maybeRequestLocationPermission() async {
    final status = await Permission.location.status;
    if (status.isGranted || status.isLimited) {
      return Future.value(true);
    }

    final result = await Permission.location.request();
    if ((result.isGranted || status.isLimited)) {
      return Future.value(true);
    } else {
      if (!mounted) {
        return false;
      }
      showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text(
              'Location Services',
              textAlign: TextAlign.center,
            ),
            content: const Text(
                'Location needs to be on in order to discover people near you.'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              CupertinoDialogAction(
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
                child: const Text('Enable in Settings'),
              ),
            ],
          );
        },
      );
      return Future.value(false);
    }
  }

  Future<_LatLong?> _getLocation() async {
    final locationService = LocationService();
    final location = await locationService.getLatLong();
    return location.when(
      value: (lat, long) {
        return Future.value(_LatLong(lat, long));
      },
      denied: () => Future.value(),
      failure: () => Future.value(),
    );
  }

  Future<void> _updateLocation() async {
    setState(() => _loading = true);

    final location = await _getLocation();
    if (location != null && mounted) {
      final profile = ref.read(userProvider).profile;
      final notifier = ref.read(userProvider.notifier);
      await updateLocation(
        context: context,
        profile: profile!,
        notifier: notifier,
        latitude: location.latitude,
        longitude: location.longitude,
      );
    }
  }

  Future<void> _fetchPageOfProfiles() async {
    final granted = await _maybeRequestLocationPermission();
    if (!mounted || !granted) {
      return;
    }

    setState(() => _loading = true);
    final location = await _getLocation();
    if (!mounted) {
      return;
    }

    if (location == null) {
      return;
    }
    setState(() => _hasLocation = true);

    final api = GetIt.instance.get<Api>();
    _discoverOperation?.cancel();
    final discoverFuture = api.getDiscover(
      location.latitude,
      location.longitude,
      seed: Api.seed,
      topic: _selectedTopic,
      minRadius: _nextMinRadius,
      page: _nextPage,
    );
    _discoverOperation = CancelableOperation.fromFuture(discoverFuture);
    final profiles = await _discoverOperation?.value;

    if (!mounted || profiles == null) {
      return;
    }
    setState(() => _loading = false);

    profiles.fold(
      (l) {
        var message = errorToMessage(l);
        message = l.when(
          network: (_) => message,
          client: (client) => client.when(
            badRequest: () => 'Unable to request users',
            unauthorized: () => message,
            notFound: () => 'Unable to find users',
            forbidden: () => message,
            conflict: () => message,
          ),
          server: (_) => message,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      },
      (r) async {
        setState(() {
          _profiles.addAll(r.profiles.map((e) => e.profile));
          _nextMinRadius = r.nextMinRadius;
          _nextPage = r.nextPage;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profiles.isEmpty) {
      if (_loading) {
        return const Center(
          child: LoadingIndicator(),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: !_hasLocation
                    ? Text(
                        'Unable to get location',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : Text(
                        _selectedTopic == null
                            ? 'Couldn\'t find any profiles'
                            : 'Couldn\'t find any "${topicLabel(_selectedTopic!)}" profiles',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Location needed at least once for nearby users
                  // (may not have granted location during onboarding)
                  setState(() => _loading = true);
                  final locationService = LocationService();
                  if (!await locationService.hasPermission()) {
                    final status = await locationService.requestPermission();
                    if (status) {
                      await _updateLocation();
                    }
                  }

                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _nextMinRadius = 0;
                    _nextPage = 0;
                  });
                  _fetchPageOfProfiles();
                },
                child: const Text('Refresh'),
              ),
            ],
          ),
        );
      }
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        return ValueListenableBuilder<double>(
          valueListenable: _pageListener,
          builder: (context, page, child) {
            final pageIndex = page.floor();
            final opacity = (page - pageIndex) * (page - pageIndex);
            if (index <= pageIndex) {
              return ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color.fromRGBO(0x00, 0x00, 0x00, opacity),
                  BlendMode.srcOver,
                ),
                child: child!,
              );
            } else {
              return ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Color.fromRGBO(0x00, 0x00, 0x00, 1 - opacity),
                  BlendMode.srcOver,
                ),
                child: child!,
              );
            }
          },
          child: UserProfileDisplay(
            key: ValueKey(profile.uid),
            profile: profile,
            play: true,
            invited: _invitedUsers.contains(profile.uid),
            onInvite: () {
              GetIt.instance.get<Mixpanel>().track(
                "send_invite",
                properties: {"type": "discover"},
              );
              setState(() => _invitedUsers.add(profile.uid));
            },
            onNext: () {},
            onBlocked: () => setState(
                () => _profiles.removeWhere(((p) => p.uid == profile.uid))),
            onBeginRecording: () {},
            onMenu: () {
              widget.carouselKey.currentState?.showMenu = true;
            },
          ),
        );
      },
    );
  }
}

class SharedProfilePage extends StatefulWidget {
  final String uid;
  const SharedProfilePage({
    super.key,
    required this.uid,
  });

  @override
  State<SharedProfilePage> createState() => _SharedProfilePageState();
}

class _SharedProfilePageState extends State<SharedProfilePage> {
  bool _loading = true;
  Profile? _profile;
  bool _invited = false;
  final _audioPlayer = JustAudioAudioPlayer();

  @override
  void initState() {
    super.initState();
    final api = GetIt.instance.get<Api>();
    api.getProfile(widget.uid).then((value) {
      if (!mounted) {
        return;
      }
      value.fold(
        (l) {
          displayError(context, l);
          setState(() => _loading = false);
        },
        (r) {
          setState(() {
            _profile = r;
            _loading = false;
          });
        },
      );
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const BackIconButton(),
        title: const Text(
          'back to discover',
        ),
      ),
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          if (_loading) {
            return const Center(
              child: LoadingIndicator(),
            );
          }

          final profile = _profile;
          if (profile == null) {
            return Center(
              child: Text(
                'Unable to get profile',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontSize: 22),
              ),
            );
          }
          return SafeArea(
            bottom: true,
            child: UserProfileDisplay(
              profile: profile,
              play: true,
              invited: _invited,
              onInvite: () {
                GetIt.instance.get<Mixpanel>().track(
                  "send_invite",
                  properties: {"type": "deep_link"},
                );
                setState(() => _invited = true);
              },
              onBeginRecording: () => _audioPlayer.stop(),
              onNext: () {},
              onBlocked: () => Navigator.of(context).pop(),
              onMenu: () {},
            ),
          );
        },
      ),
    );
  }
}

class _LatLong {
  final double latitude;
  final double longitude;
  const _LatLong(
    this.latitude,
    this.longitude,
  );
}

class ScrollToDiscoverTopNotifier extends ValueNotifier<void> {
  ScrollToDiscoverTopNotifier() : super(null);

  void scrollToTop() => notifyListeners();
}
