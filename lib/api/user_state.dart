import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/util/image_manip.dart';

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

final userProvider = StateNotifierProvider<UserStateNotifier, UserState>((ref) {
  return UserStateNotifier();
});

class UserStateNotifier extends StateNotifier<UserState> {
  UserStateNotifier() : super(const UserState());

  void uid(String uid) => state = state.copyWith(uid: uid);

  void profile(Profile? profile) => state = state.copyWith(profile: profile);

  void collections(List<Collection> collections) =>
      state = state.copyWith(collections: collections);

  UserState get userState => state;
}

@freezed
class UserState with _$UserState {
  const factory UserState({
    @Default('') String uid,
    @Default(null) Profile? profile,
    @Default(<Collection>[]) List<Collection> collections,
  }) = _UserState;
}

final userProvider2 =
    StateNotifierProvider<UserStateNotifier2, UserState2>((ref) {
  final userStateNotifier = UserStateNotifier2(
    api: ref.watch(apiProvider),
    messageNotifier: ref.read(messageProvider.notifier),
  );

  _initUserState(
    api: ref.read(apiProvider),
    authState: ref.read(authProvider),
    onSignedIn: (account) {
      ref.read(userProvider.notifier).uid(account.profile.uid);
      ref.read(userProvider.notifier).profile(account.profile);
      userStateNotifier.signedIn(account);
    },
    onSignedOut: () => userStateNotifier.guest(),
    onAuthorizedButNoAccount: () {
      final authState = ref.read(authProvider);
      authState.map(
        guest: (_) => userStateNotifier.guest(),
        signedIn: (_) =>
            ref.read(authProvider.notifier).deleteHangingAuthAccount(),
      );
    },
  );

  return userStateNotifier;
});

void _initUserState({
  required Api api,
  required AuthState authState,
  required void Function(Account account) onSignedIn,
  required void Function() onSignedOut,
  required void Function() onAuthorizedButNoAccount,
}) async {
  // Get user profile
  final loggedIn = authState.map(
    guest: (_) => false,
    signedIn: (_) => true,
  );
  if (!loggedIn) {
    onAuthorizedButNoAccount();
    return;
  }
  final getAccountResult = await getAccount(api);
  getAccountResult.map(
    logIn: (logIn) => onSignedIn(logIn.account),
    signUp: (_) => onAuthorizedButNoAccount(),
    retry: (_) {
      // TODO: Handle error
    },
  );
}

class UserStateNotifier2 extends StateNotifier<UserState2> {
  final Api _api;
  final MessageStateNotifier _messageNotifier;

  UserStateNotifier2({
    required Api api,
    required MessageStateNotifier messageNotifier,
  })  : _api = api,
        _messageNotifier = messageNotifier,
        super(const _Guest());

  UserState2 get userState => state;

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

  Future<void> _cacheCollections(String uid) async {
    final result = await _api.getCollections(uid);
    if (!mounted) {
      return;
    }
    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) => state = signedIn.copyWith(collections: r),
        );
      },
    );
  }

  Future<void> cacheChatrooms() => _cacheChatrooms();

  Future<Either<ApiError, Account>> createAccount(
    AccountCreationParams params,
  ) async {
    final photos = params.photos;
    if (photos == null) {
      debugPrint('Photos were null when creating account');
      return Future.value(const Left(ApiClientError(ClientErrorBadRequest())));
    }

    final downscaled = await _downscalePhotos(photos);
    if (downscaled == null) {
      debugPrint('Failed to downscale profile images');
      return Future.value(const Left(ApiClientError(ClientErrorBadRequest())));
    }

    return _api.createAccount(params.copyWith(photos: downscaled));
  }

  Future<Either<ApiError, Profile>> updateName(String name) async {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        if (name.isEmpty || name == signedIn.account.profile.name) {
          return Right(signedIn.account.profile);
        }
        final result = await _api.updateProfile(
          signedIn.account.profile.uid,
          signedIn.account.profile.copyWith(name: name),
        );
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

  void updateLocationVisibility(LocationVisibility visibility) {
    state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) async {
        state = signedIn.copyWith.account.location(visibility: visibility);
        final result = await _api.updateLocationVisibility(visibility);
        if (!mounted) {
          return;
        }
        result.fold(
          (l) => _messageNotifier.emitMessage(errorToMessage(l)),
          (r) {},
        );
      },
    );
  }

  Future<void> refreshChatrooms() {
    return state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) => _cacheChatrooms(),
    );
  }

  Future<Either<ApiError, void>> deleteChatroom(String uid) {
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
        (ref) => AccountCreationParamsNotifier());

class AccountCreationParamsNotifier
    extends StateNotifier<AccountCreationParams> {
  AccountCreationParamsNotifier() : super(const AccountCreationParams());

  void photos(List<File> photos) => state = state.copyWith(photos: photos);

  void audio(File audio) => state = state.copyWith(audio: audio);

  void name(String name) => state = state.copyWith(name: name);

  void age(int age) => state = state.copyWith(age: age);

  void gender(Gender gender) => state = state.copyWith(gender: gender);

  void latLong(LatLong latLong) => state = state.copyWith(latLong: latLong);
}

@freezed
class UserState2 with _$UserState2 {
  const UserState2._();

  const factory UserState2.guest({
    @Default(true) bool byDefault,
  }) = _Guest;

  const factory UserState2.signedIn({
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

Future<GetAccountResult> getAccount(Api api) async {
  final result = await api.getAccount();
  return result.fold(
    (l) {
      const retry = _Retry();
      return l.map<GetAccountResult>(
        network: (_) => retry,
        client: (apiClientError) {
          return apiClientError.error.map(
            badRequest: (_) => retry,
            unauthorized: (_) => retry,
            notFound: (_) => const _SignUp(),
            forbidden: (_) => retry,
            conflict: (_) => retry,
          );
        },
        server: (_) => retry,
      );
    },
    (r) => _LogIn(r),
  );
}

@freezed
class GetAccountResult with _$GetAccountResult {
  const factory GetAccountResult.logIn(Account account) = _LogIn;
  const factory GetAccountResult.signUp() = _SignUp;
  const factory GetAccountResult.retry() = _Retry;
}
