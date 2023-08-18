import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/util/image_manip.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class UserProfileCache extends ConsumerStatefulWidget {
  final Widget Function(
    BuildContext context,
    File? cachedPhoto,
  ) builder;

  const UserProfileCache({
    super.key,
    required this.builder,
  });

  @override
  ConsumerState<UserProfileCache> createState() => _UserProfileCacheState();
}

class _UserProfileCacheState extends ConsumerState<UserProfileCache> {
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    getTemporaryDirectory().then((dir) async {
      final file = File(path.join(dir.path, 'user', 'photo.png'));
      final exists = await file.exists();
      if (mounted) {
        if (exists) {
          setState(() => _photoFile = file);
        }
        _listenToProfile(file);
      }
    });
  }

  void _listenToProfile(File photoFile) {
    ref.listenManual<_ProfileCheck>(
      userProvider2.select((p) {
        return p.map(
          guest: (guest) => _ProfileCheck(
            byDefault: guest.byDefault,
            profile: null,
          ),
          signedIn: (signedIn) => _ProfileCheck(
            byDefault: false,
            profile: signedIn.account.profile,
          ),
        );
      }),
      (previous, next) {
        final photoChanged = previous?.profile?.photo != next.profile?.photo;
        final profile = next.profile;
        if (photoChanged && profile != null) {
          _cacheProfile(profile, photoFile).then((_) {
            if (mounted) {
              setState(() => _photoFile = photoFile);
            }
          });
        }
      },
      fireImmediately: true,
    );
  }

  Future<void> _cacheProfile(Profile profile, File photoFile) async {
    debugPrint('Caching profile ${profile.uid}');

    if (!mounted) {
      return;
    }
    final bytes = await _downloadImage(
      profile.photo,
      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
    );
    if (bytes == null) {
      return;
    }
    try {
      await photoFile.create(recursive: true);
    } on FileSystemException catch (e) {
      debugPrint(e.message);
    }
    await photoFile.writeAsBytes(bytes);
  }

  Future<Uint8List?> _downloadImage(
    String url, {
    required double devicePixelRatio,
  }) async {
    final image = await fetchImage(
      NetworkImage(url),
      size: const Size(50, 50),
      pixelRatio: devicePixelRatio,
    );
    final bytes = await image.toByteData(format: ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(
      authProvider.select((p) {
        return p.map(
          guest: (guest) => false,
          signedIn: (signedIn) => true,
        );
      }),
    );
    return widget.builder(context, loggedIn ? _photoFile : null);
  }
}

class _ProfileCheck {
  final bool byDefault;
  final Profile? profile;

  _ProfileCheck({
    required this.byDefault,
    required this.profile,
  });
}
