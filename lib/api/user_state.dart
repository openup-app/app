import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/util/image_manip.dart';
import 'package:openup/waitlist/waitlist_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

part 'user_state.freezed.dart';

final apiProvider = Provider<Api>((ref) => throw 'Api is uninitialized');

final messageProvider =
    StateNotifierProvider<MessageStateNotifier, String?>((ref) {
  return MessageStateNotifier();
});

class MessageStateNotifier extends StateNotifier<String?> {
  MessageStateNotifier() : super(null);

  void emitMessage(String message) => state = message;
}

final appInitProvider = FutureProvider<AppInit?>((ref) async {
  final api = ref.watch(apiProvider);
  final waitlistUser = ref.watch(waitlistProvider);
  if (waitlistUser == null) {
    // This also means there is no authenticated user
    return null;
  }
  final accountState = await getAccount(api, waitlistUser);
  return accountState.map(
    (value) => value,
    retry: (_) => null,
  );
}, dependencies: [apiProvider, waitlistProvider]);

final userProvider = StateNotifierProvider<UserStateNotifier, UserState>(
  (ref) {
    final userStateNotifier = UserStateNotifier(
      api: ref.watch(apiProvider),
      messageNotifier: ref.read(messageProvider.notifier),
      analytics: ref.read(analyticsProvider),
    );
    final appInit = ref.watch(appInitProvider);
    if (!(appInit.hasValue && appInit.value != null)) {
      return userStateNotifier;
    } else {
      final accountState = appInit.value!.accountState;
      return accountState.map(
        account: (accountState) =>
            userStateNotifier..signedIn(accountState.account),
        needsSignup: (_) => userStateNotifier,
        none: (_) => userStateNotifier,
      );
    }
  },
  dependencies: [
    apiProvider,
    messageProvider,
    appInitProvider,
    analyticsProvider
  ],
);

class UserStateNotifier extends StateNotifier<UserState> {
  final Api _api;
  final MessageStateNotifier _messageNotifier;
  final Analytics _analytics;

  UserStateNotifier({
    required Api api,
    required MessageStateNotifier messageNotifier,
    required Analytics analytics,
  })  : _api = api,
        _messageNotifier = messageNotifier,
        _analytics = analytics,
        super(const _Guest());

  UserState get userState => state;

  void guest() => state = const _Guest(byDefault: false);

  void signedIn(Account account) async {
    state = _SignedIn(account: account);
    _cacheChatrooms();
  }

  Future<void> _cacheChatrooms() async {
    final result = await _api.getChatrooms();
    if (!mounted) {
      return;
    }
    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) => state = signedIn.copyWith(chatrooms: r),
        );
      },
    );
  }

  Future<void> cacheChatrooms() => _cacheChatrooms();

  Future<Either<ApiError, Account>> createAccount(
    AccountCreationParams params,
  ) {
    return _api.createAccount(params);
  }

  Future<Either<ApiError, Profile>> updateName(String name) async {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        if (name.isEmpty || name == signedIn.account.profile.name) {
          return Right(signedIn.account.profile);
        }

        _analytics.trackUpdateName(
          oldName: signedIn.account.profile.name,
          newName: name,
        );
        final result =
            await _api.updateProfileName(signedIn.account.profile.uid, name);
        return result.fold(
          (l) => Left(l),
          (r) {
            if (mounted) {
              state = signedIn.copyWith.account(profile: r);
            }
            return Right(r);
          },
        );
      },
    );
  }

  Future<void> updateCollection(String collectionId) async {
    await state.map(
      guest: (_) async {
        _messageNotifier.emitMessage(
            errorToMessage(const ApiError.client(ClientError.unauthorized())));
        return false;
      },
      signedIn: (signedIn) async {
        final result = await _api.updateProfileCollection(
          uid: signedIn.account.profile.uid,
          collectionId: collectionId,
        );
        if (!mounted) {
          return;
        }
        return result.fold(
          (l) => _messageNotifier.emitMessage(errorToMessage(l)),
          (r) => state = signedIn.copyWith.account(profile: r),
        );
      },
    );
  }

  Future<bool> updateGalleryPhoto({
    required int index,
    required File photo,
  }) async {
    _analytics.trackGalleryReplacePhoto();
    return state.map(
      guest: (_) {
        _messageNotifier.emitMessage(
            errorToMessage(const ApiError.client(ClientError.unauthorized())));
        return false;
      },
      signedIn: (signedIn) async {
        final downscaled = await downscaleImage(photo);
        if (downscaled == null) {
          return false;
        }
        final result = await _api.updateGalleryPhoto(
          signedIn.account.profile.uid,
          index,
          downscaled,
        );
        return result.fold(
          (l) {
            _messageNotifier.emitMessage(errorToMessage(l));
            return false;
          },
          (r) {
            if (mounted) {
              state = signedIn.copyWith.account(profile: r);
            }
            return true;
          },
        );
      },
    );
  }

  Future<bool> deleteGalleryPhoto(int index) async {
    _analytics.trackGalleryDeletePhoto();
    return state.map(
      guest: (_) {
        _messageNotifier.emitMessage(
            errorToMessage(const ApiError.client(ClientError.unauthorized())));
        return false;
      },
      signedIn: (signedIn) async {
        final gallery = signedIn.account.profile.gallery;
        if (gallery.length <= 1) {
          return false;
        }
        state = signedIn.copyWith.account
            .profile(gallery: List.of(gallery)..removeAt(index));
        final result =
            await _api.deleteGalleryPhoto(signedIn.account.profile.uid, index);
        return result.fold(
          (l) {
            _messageNotifier.emitMessage(errorToMessage(l));
            return false;
          },
          (r) {
            if (mounted) {
              state = signedIn.copyWith.account(profile: r);
            }
            return true;
          },
        );
      },
    );
  }

  Future<bool> updateAudioBio(Uint8List bytes) async {
    _analytics.trackUpdateAudioBio();
    return state.map(
      guest: (_) {
        _messageNotifier.emitMessage(
            errorToMessage(const ApiError.client(ClientError.unauthorized())));
        return false;
      },
      signedIn: (signedIn) async {
        final result =
            await _api.updateProfileAudio(signedIn.account.profile.uid, bytes);
        return result.fold(
          (l) {
            _messageNotifier.emitMessage(errorToMessage(l));
            return false;
          },
          (r) {
            if (mounted) {
              state = signedIn.copyWith.account(profile: r);
            }
            return true;
          },
        );
      },
    );
  }

  void updateLocation(LatLong latLong) {
    state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) => _api.updateLocation(latLong),
    );
  }

  Future<void> refreshChatrooms() {
    return state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) => _cacheChatrooms(),
    );
  }

  Future<Either<ApiError, void>> deleteChatroom(String uid) {
    _analytics.trackDeleteFriend();
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        final result = await _api.deleteChatroom(uid);
        return result.fold<Either<ApiError, void>>(
          (l) => Left(l),
          (r) {
            if (mounted) {
              state = signedIn.copyWith(chatrooms: r);
            }
            return const Right(null);
          },
        );
      },
    );
  }

  void openChatroom(String uid) {
    state.map(
      guest: (_) {},
      signedIn: (signedIn) {
        final index =
            signedIn.chatrooms?.indexWhere((c) => c.profile.uid == uid);
        if (index != null && index != -1) {
          final chatrooms = signedIn.chatrooms!;
          final newChatrooms = List.of(chatrooms)
            ..replaceRange(
              index,
              index + 1,
              [chatrooms[index].copyWith(unreadCount: 0)],
            );
          state = signedIn.copyWith(chatrooms: newChatrooms);
        }
      },
    );
  }

  void acceptChatroom(String uid) {
    state.map(
      guest: (_) {},
      signedIn: (signedIn) {
        final chatrooms = signedIn.chatrooms;
        if (chatrooms == null) {
          return;
        }
        final index = chatrooms.indexWhere((c) => c.profile.uid == uid);
        if (index != -1) {
          final accepted =
              chatrooms[index].copyWith(inviteState: ChatroomState.accepted);
          final newChatrooms = List.of(chatrooms);
          newChatrooms.replaceRange(index, index + 1, [accepted]);
          state = signedIn.copyWith(chatrooms: newChatrooms);
        }
      },
    );
  }

  Future<void> sendMessage({
    required String uid,
    required Uint8List audio,
  }) {
    return state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) async {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().toIso8601String();
        final file = File(path.join(tempDir.path, 'message_$timestamp.m4a'));
        await file.writeAsBytes(audio);
        await _api.sendMessage(uid, ChatType.audio, file.path);
      },
    );
  }

  Future<Either<ApiError, Collection>> createCollection({
    required List<File> photos,
    required File? audio,
    bool useAsProfile = false,
  }) {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        final downscaled = await _downscalePhotos(photos);
        if (downscaled == null) {
          return Future.value(
              const Left(ApiError.client(ClientError.badRequest())));
        }

        final result = await _api.createCollection(
          downscaled.map((e) => e.path).toList(),
          useAsProfile: useAsProfile,
        );
        return result.fold<Either<ApiError, Collection>>(
          (l) => Left(l),
          (r) {
            final collections = signedIn.collections == null
                ? <Collection>[]
                : List.of(signedIn.collections!);
            collections.insert(0, r);
            if (mounted) {
              state = signedIn.copyWith(collections: collections);
            }
            return Right(r);
          },
        );
      },
    );
  }

  Future<Either<ApiError, void>> deleteCollection(String id) {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) {
        final collections = signedIn.collections == null
            ? <Collection>[]
            : List.of(signedIn.collections!);
        collections.removeWhere((c) => c.collectionId == id);
        state = signedIn.copyWith(collections: collections);
        return _api.deleteCollection(id);
      },
    );
  }

  Future<List<File>?> _downscalePhotos(List<File> photos) async {
    final downscaledImages = <File>[];
    for (final photo in photos) {
      final downscaled = await downscaleImage(photo);
      if (downscaled == null) {
        return null;
      }
      downscaledImages.add(downscaled);
    }
    return downscaledImages;
  }
}

final accountCreationParamsProvider =
    StateNotifierProvider<AccountCreationParamsNotifier, AccountCreationParams>(
  (ref) {
    final userStateNotifier = ref.read(userProvider.notifier);
    return AccountCreationParamsNotifier(
      api: ref.read(apiProvider),
      analytics: ref.read(analyticsProvider),
      onAccount: userStateNotifier.signedIn,
    );
  },
  dependencies: [apiProvider, analyticsProvider],
);

class AccountCreationParamsNotifier
    extends StateNotifier<AccountCreationParams> {
  final Api _api;
  final Analytics _analytics;
  final void Function(Account account) _onAccount;

  AccountCreationParamsNotifier({
    required Api api,
    required Analytics analytics,
    required void Function(Account account) onAccount,
  })  : _api = api,
        _analytics = analytics,
        _onAccount = onAccount,
        super(const AccountCreationParams());

  void audio(File audio) => state = state.copyWith(audio: audio);

  void name(String name) => state = state.copyWith(name: name);

  void age(int age) => state = state.copyWith(age: age);

  void latLong(LatLong latLong) => state = state.copyWith(latLong: latLong);

  Future<Either<ApiError, void>?> signUp() async {
    if (!state.valid) {
      return null;
    }
    _analytics.trackCreateAccount();

    final result = await _api.createAccount(state);
    if (!mounted) {
      return null;
    }

    return result.fold(
      (l) => Left(l),
      (r) {
        _analytics.setUserProperty('name', r.profile.name);
        _analytics.setUserProperty('age', r.profile.age);
        _onAccount(r);
        return const Right(null);
      },
    );
  }
}

@freezed
class UserState with _$UserState {
  const UserState._();

  const factory UserState.guest({
    @Default(true) bool byDefault,
  }) = _Guest;

  const factory UserState.signedIn({
    required Account account,
    @Default(null) List<Chatroom>? chatrooms,
    @Default(null) List<Collection>? collections,
  }) = _SignedIn;

  int get unreadCount {
    return map(
      guest: (_) => 0,
      signedIn: (signedIn) =>
          (signedIn.chatrooms ?? []).fold(0, (p, e) => p + e.unreadCount),
    );
  }
}

Future<GetAccountResult> getAccount(Api api, WaitlistUser waitlistUser) async {
  final results =
      await Future.wait([api.getAppAvailability(), api.getAccountState()]);
  final appAvailabilityResult = results[0] as Either<ApiError, AppAvailability>;
  final accountStateResult = results[1] as Either<ApiError, AccountState>;
  if (appAvailabilityResult.isLeft()) {
    return appAvailabilityResult.fold(
      (l) => _Retry(l),
      (r) => throw 'Invalid state',
    );
  }

  final appAvailability = appAvailabilityResult.fold(
    (l) => throw 'Invalid state',
    (r) => r,
  );

  return accountStateResult.fold(
    (l) => _Retry(l),
    (r) => GetAccountResult(appAvailability, waitlistUser, r),
  );
}

final uidProvider = Provider<String>(
  (ref) {
    return ref.watch(userProvider.select((s) {
      return s.map(
        guest: (_) => throw 'Unable to get uid: user not signed in',
        signedIn: (signedIn) => signedIn.account.profile.uid,
      );
    }));
  },
  dependencies: [userProvider],
);

@freezed
class GetAccountResult with _$GetAccountResult {
  const factory GetAccountResult(
    AppAvailability appAvailability,
    WaitlistUser waitlistUser,
    AccountState accountState,
  ) = AppInit;
  const factory GetAccountResult.retry(ApiError e) = _Retry;
}
