import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';
import 'package:openup/util/location_service.dart';

part 'user_state.freezed.dart';

final locationProvider =
    StateNotifierProvider<LocationNotifier, LatLongValue?>((ref) {
  return LocationNotifier();
});

class LocationNotifier extends StateNotifier<LatLongValue?> {
  LocationNotifier() : super(null);

  void update(LatLongValue? value) => state = value;
}

final apiProvider = Provider<Api>((ref) => throw 'Api is uninitialized');

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
  final api = ref.watch(apiProvider);
  return UserStateNotifier2(api);
});

class UserStateNotifier2 extends StateNotifier<UserState2> {
  final Api _api;

  UserStateNotifier2(this._api) : super(const _Guest());

  UserState2 get userState => state;

  void guest() => state = const _Guest();

  void signedIn(Profile profile) async {
    state = _SignedIn(profile: profile);

    _cacheChatrooms();
    _cacheCollections(profile.uid);
  }

  Future<void> _cacheChatrooms() async {
    final result = await _api.getChatrooms();
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

  Future<Either<ApiError, Profile>> updateName(String name) async {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        if (name.isEmpty || name == signedIn.profile.name) {
          return Right(signedIn.profile);
        }
        final result = await _api.updateProfile(
          signedIn.profile.uid,
          signedIn.profile.copyWith(name: name),
        );
        return result.fold(
          (l) => Left(l),
          (r) {
            state = signedIn.copyWith(profile: r);
            return Right(r);
          },
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
            state = signedIn.copyWith(chatrooms: r);
            return const Right(null);
          },
        );
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
        final result =
            await uploadCollection(api: _api, photos: photos, audio: audio);
        return result.fold<Either<ApiError, Collection>>(
          (l) => Left(l),
          (r) {
            final collections = signedIn.collections == null
                ? null
                : List.of(signedIn.collections!);
            collections?.insert(0, r);
            state = signedIn.copyWith(collections: collections);
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
      signedIn: (signedIn) async {
        final result = await _api.deleteCollection(id);
        return result.fold<Either<ApiError, void>>(
          (l) => Left(l),
          (r) {
            final collections = signedIn.collections == null
                ? null
                : List.of(signedIn.collections!);
            collections?.removeWhere((c) => c.collectionId == id);
            state = signedIn.copyWith(collections: collections);
            return const Right(null);
          },
        );
      },
    );
  }
}

final accountCreationParamsProvider =
    StateNotifierProvider<AccountCreationParamsNotifier, AccountCreationParams>(
        (ref) => AccountCreationParamsNotifier());

class AccountCreationParamsNotifier
    extends StateNotifier<AccountCreationParams> {
  AccountCreationParamsNotifier() : super(const AccountCreationParams());

  void photos(List<String> photos) => state = state.copyWith(photos: photos);

  void audio(String audio) => state = state.copyWith(audio: audio);

  void name(String name) => state = state.copyWith(name: name);

  void age(int age) => state = state.copyWith(age: age);

  void gender(Gender gender) => state = state.copyWith(gender: gender);

  void location(AccountCreationLocation location) =>
      state = state.copyWith(location: location);
}

@freezed
class UserState2 with _$UserState2 {
  const UserState2._();

  const factory UserState2.guest() = _Guest;

  const factory UserState2.signedIn({
    required Profile profile,
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
  const factory GetAccountResult.logIn(Profile profile) = _LogIn;
  const factory GetAccountResult.signUp() = _SignUp;
  const factory GetAccountResult.retry() = _Retry;
}
