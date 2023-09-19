import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/api/chat_api.dart';
import 'package:openup/auth/auth_provider.dart';
import 'package:openup/util/image_manip.dart';
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
    analytics: ref.read(analyticsProvider),
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
        signedIn: (_) {
          ref.read(authProvider.notifier).deleteHangingAuthAccount();
          userStateNotifier.guest();
        },
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
    retry: (e) {
      // TODO: Handle error
      debugPrint(e.toString());
    },
  );
}

class UserStateNotifier2 extends StateNotifier<UserState2> {
  final Api _api;
  final MessageStateNotifier _messageNotifier;
  final Analytics _analytics;

  UserStateNotifier2({
    required Api api,
    required MessageStateNotifier messageNotifier,
    required Analytics analytics,
  })  : _api = api,
        _messageNotifier = messageNotifier,
        _analytics = analytics,
        super(const _Guest());

  UserState2 get userState => state;

  void guest() => state = const _Guest(byDefault: false);

  void signedIn(Account account) async {
    state = _SignedIn(account: account);
    _cacheHostingEvents(account.profile.uid);
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

  Future<void> _cacheHostingEvents(String uid) async {
    final result = await _api.getMyHostedEvents(uid);
    if (!mounted) {
      return;
    }
    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) => state = signedIn.copyWith(hostingEvents: r),
        );
      },
    );
  }

  Future<void> _cacheAttendingEvents(String uid) async {
    final result = await _api.getMyAttendingEvents();
    if (!mounted) {
      return;
    }
    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) => state = signedIn.copyWith(attendingEvents: r),
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

    _analytics.trackCreateAccount();
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

  void updateLocationVisibility(LocationVisibility visibility) {
    _analytics.trackUpdateVisibility(visibility);
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
            signedIn.chatrooms?.indexWhere((c) => c.profile.profile.uid == uid);
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
        final index = chatrooms.indexWhere((c) => c.profile.profile.uid == uid);
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

  Future<bool> createEvent(EventSubmission submission) async {
    final result = await _api.createEvent(submission);
    if (!mounted) {
      return false;
    }

    return result.fold(
      (l) => false,
      (r) {
        return state.map(
          guest: (_) => false,
          signedIn: (signedIn) {
            state = signedIn.copyWith(
                hostingEvents: List.of(signedIn.hostingEvents ?? [])..add(r));
            return true;
          },
        );
      },
    );
  }

  Future<void> deleteEvent(String eventId) async {
    final result = await _api.deleteEvent(eventId);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) {
            state = signedIn.copyWith(
              hostingEvents: List.of(signedIn.hostingEvents ?? [])
                ..removeWhere((e) => e.id == eventId),
            );
          },
        );
      },
    );
  }

  Future<void> updateEvent(String eventId, EventSubmission submission) async {
    final result = await _api.updateEvent(eventId, submission);
    if (!mounted) {
      return;
    }

    result.fold(
      (l) {},
      (r) {
        state.map(
          guest: (_) {},
          signedIn: (signedIn) {
            final index =
                signedIn.hostingEvents?.indexWhere((e) => e.id == eventId);
            if (index != null && index != -1) {
              state = signedIn.copyWith(
                hostingEvents: List.of(signedIn.hostingEvents ?? [])
                  ..replaceRange(index, index + 1, [r]),
              );
            }
          },
        );
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
  final userStateNotifier2 = ref.read(userProvider2.notifier);
  return AccountCreationParamsNotifier(
      api: ref.read(apiProvider),
      analytics: ref.read(analyticsProvider),
      onAccount: (account) {
        userStateNotifier.profile(account.profile);
        userStateNotifier2.signedIn(account);
      });
});

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

  void photos(List<File> photos) => state = state.copyWith(photos: photos);

  void audio(File audio) => state = state.copyWith(audio: audio);

  void name(String name) => state = state.copyWith(name: name);

  void age(int age) => state = state.copyWith(age: age);

  void gender(Gender gender) => state = state.copyWith(gender: gender);

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
        _analytics.setUserProperty('gender', r.profile.gender.name);
        _onAccount(r);
        return const Right(null);
      },
    );
  }
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
    @Default(null) List<Event>? hostingEvents,
    @Default(null) List<Event>? attendingEvents,
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
      return l.map<GetAccountResult>(
        network: (_) => _Retry(l),
        client: (apiClientError) {
          return apiClientError.error.map(
            badRequest: (_) => _Retry(l),
            unauthorized: (_) => _Retry(l),
            notFound: (_) => const _SignUp(),
            forbidden: (_) => _Retry(l),
            conflict: (_) => _Retry(l),
          );
        },
        server: (e) => _Retry(l),
      );
    },
    (r) => _LogIn(r),
  );
}

@freezed
class GetAccountResult with _$GetAccountResult {
  const factory GetAccountResult.logIn(Account account) = _LogIn;
  const factory GetAccountResult.signUp() = _SignUp;
  const factory GetAccountResult.retry(ApiError e) = _Retry;
}
