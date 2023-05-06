import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/api_util.dart';

part 'user_state.freezed.dart';

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
  return UserStateNotifier2();
});

class UserStateNotifier2 extends StateNotifier<UserState2> {
  UserStateNotifier2() : super(const _Guest());

  UserState2 get userState => state;

  void guest() => state = const _Guest();

  void signedIn(Profile profile) async {
    state = _SignedIn(profile: profile);

    _cacheChatrooms(profile.uid);
    _cacheCollections(profile.uid);
  }

  Future<void> _cacheChatrooms(String uid) async {
    final result = await GetIt.instance.get<Api>().getChatrooms(uid);
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
    final result = await GetIt.instance.get<Api>().getCollections(uid);
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

  Future<void> refreshChatrooms() {
    return state.map(
      guest: (_) => Future.value(),
      signedIn: (signedIn) => _cacheChatrooms(signedIn.profile.uid),
    );
  }

  Future<Either<ApiError, void>> deleteChatroom(String uid) {
    return state.map(
      guest: (_) =>
          Future.value(const Left(ApiError.client(ClientErrorUnauthorized()))),
      signedIn: (signedIn) async {
        final result = await Future.delayed(const Duration(seconds: 1))
            .then((value) => const Right(null));
        return result.fold<Either<ApiError, void>>(
          (l) => Left(l),
          (r) {
            final chatrooms = signedIn.collections == null
                ? null
                : List.of(signedIn.chatrooms!);
            chatrooms?.removeWhere((c) => c.profile.uid == uid);
            state = signedIn.copyWith(chatrooms: chatrooms);
            return const Right(null);
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
        final result = await uploadCollection(photos: photos, audio: audio);
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
        final result = await GetIt.instance.get<Api>().deleteCollection(id);
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

@freezed
class UserState2 with _$UserState2 {
  const factory UserState2.guest() = _Guest;

  const factory UserState2.signedIn({
    required Profile profile,
    @Default(null) List<Chatroom>? chatrooms,
    @Default(null) List<Collection>? collections,
  }) = _SignedIn;
}
