import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openup/api/chat_api.dart';
import 'package:openup/main.dart';

part 'api.freezed.dart';
part 'api.g.dart';

class Api {
  static final _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static String seed = '';

  final String _urlBase;

  Api({
    required String host,
    required int port,
    String? authToken,
  }) : _urlBase = 'http://$host:$port' {
    if (authToken != null) {
      this.authToken = authToken;
    }
  }

  set authToken(String value) {
    _headers['Authorization'] = 'Bearer $value';
  }

  Future<Either<ApiError, AccountCreationResult>> createAccount() {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(AccountCreationResult.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, void>> deleteAccount() {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/account'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> signOut() {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account/sign_out'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, Profile>> getProfile(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/profiles/$uid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(Profile.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, ProfileWithCollections>> getProfileWithCollections(
      String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/profiles/$uid?collections=true'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(
            ProfileWithCollections.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, void>> updateProfile(String uid, Profile profile) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/profiles/$uid'),
          headers: _headers,
          body: jsonEncode(profile.toJson()),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, String>> updateProfileAudio(
    String uid,
    Uint8List audio,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/profiles/$uid/audio'),
          headers: {
            ..._headers,
            'Content-Type': 'application/octet-stream',
          },
          body: audio,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(json['url']);
      },
    );
  }

  Future<Either<ApiError, void>> updateProfileCollection({
    required String collectionId,
    required String uid,
  }) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/profiles/$uid/collection/$collectionId'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, Map<String, int>>> getUnreadMessageCount(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/unread_message_count'),
          headers: _headers,
        );
      },
      handleSuccess: (response) =>
          Right(Map<String, int>.from(jsonDecode(response.body))),
    );
  }

  Future<Either<ApiError, void>> addNotificationTokens({
    String? fcmMessagingAndVoipToken,
    String? apnMessagingToken,
    String? apnVoipToken,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/accounts/notification_tokens'),
          headers: _headers,
          body: jsonEncode({
            'tokens': [
              if (fcmMessagingAndVoipToken != null)
                {
                  'token': fcmMessagingAndVoipToken,
                  'messaging': true,
                  'voip': true,
                  'service': 'fcm',
                },
              if (apnMessagingToken != null)
                {
                  'token': apnMessagingToken,
                  'messaging': true,
                  'voip': false,
                  'service': 'apn',
                },
              if (apnVoipToken != null)
                {
                  'token': apnVoipToken,
                  'messaging': false,
                  'voip': true,
                  'service': 'apn',
                },
            ]
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> reportUser({
    required String uid,
    required String reportedUid,
    required String reason,
    String? extra,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$reportedUid/reports'),
          headers: _headers,
          body: jsonEncode({
            'reporterUid': uid,
            'reason': reason,
            'extra': extra,
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, String>> call(
    String calleeUid,
    bool video, {
    required bool group,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/calls/'),
          headers: _headers,
          body: jsonEncode({
            'calleeUid': calleeUid,
            'video': video,
            'group': group,
          }),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(json['rid']);
      },
    );
  }

  Future<Either<ApiError, void>> contactUs({
    required String uid,
    required String message,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/support/contact_us'),
          headers: _headers,
          body: jsonEncode({
            'uid': uid,
            'message': message,
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<Chatroom>>> getChatrooms() async {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/chats'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return Right(
            List<Chatroom>.from(list.map((e) => Chatroom.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, Chatroom>> getChatroom(String otherUid) async {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/chats/$otherUid/info'),
          headers: _headers,
        );
      },
      handleSuccess: (response) =>
          Right(Chatroom.fromJson(jsonDecode(response.body))),
    );
  }

  Future<Either<ApiError, List<ChatMessage>>> getMessages(
    String otherUid, {
    DateTime? startDate,
    int limit = 10,
  }) async {
    return _request(
      makeRequest: () {
        final query =
            '${startDate == null ? '' : 'startDate=${startDate.toIso8601String()}&'}limit=$limit';
        return http.get(
          Uri.parse('$_urlBase/chats/$otherUid?$query'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return Right(
            List<ChatMessage>.from(list.map((e) => ChatMessage.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, ChatMessage>> sendMessage(
    String otherUid,
    ChatType type,
    String content,
  ) async {
    final uri = Uri.parse('$_urlBase/chats/$otherUid');
    switch (type) {
      case ChatType.audio:
        return _requestStreamedResponseAsFuture(
          makeRequest: () async {
            final request = http.MultipartRequest('POST', uri);
            request.headers.addAll(_headers);
            request.fields['type'] = type.name;
            request.files.add(
              await http.MultipartFile.fromPath('media', content),
            );
            return request.send();
          },
          handleSuccess: (response) {
            return Right(ChatMessage.fromJson(jsonDecode(response.body)));
          },
        );
    }
  }

  Future<Either<ApiError, DiscoverPage>> getDiscover(
    double? latitude,
    double? longitude, {
    String? seed,
    Gender? gender,
    double? minRadius,
    int? page,
  }) {
    return _request(
      makeRequest: () {
        final locationQuery = (latitude == null || longitude == null)
            ? null
            : 'lat=$latitude&long=$longitude';
        final seedQuery = seed == null ? null : 'seed=$seed';
        final genderQuery = gender == null ? null : 'gender=${gender.name}';
        final minRadiusQuery =
            minRadius == null ? null : 'minRadius=$minRadius';
        final pageQuery = page == null ? null : 'page=$page';
        final hasOptions = latitude != null ||
            longitude != null ||
            seedQuery != null ||
            genderQuery != null ||
            minRadiusQuery != null ||
            pageQuery != null;
        return http.get(
          Uri.parse('$_urlBase/discover${hasOptions ? '?' : ''}${[
            locationQuery,
            seedQuery,
            genderQuery,
            minRadiusQuery,
            pageQuery,
          ].where((q) => q != null).join('&')}'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(DiscoverPage.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, void>> declineInvitation(String otherUid) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/chats/$otherUid/decline'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return const Right(null);
      },
    );
  }

  Future<Either<ApiError, Collection>> createCollection(
    List<String> photos,
    String? audio, {
    bool useAsProfile = false,
  }) {
    return _requestStreamedResponseAsFuture(
      makeRequest: () async {
        final query = useAsProfile ? '?use_as_profile=true' : '';
        final uri = Uri.parse('$_urlBase/collections$query');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        request.files.addAll([
          for (final photo in photos)
            await http.MultipartFile.fromPath('photos', photo),
          if (audio != null) await http.MultipartFile.fromPath('audio', audio),
        ]);
        return request.send();
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Collection.fromJson(json['collection']));
      },
    );
  }

  Future<Either<ApiError, void>> deleteCollection(String collectionId) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/collections/$collectionId'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<Collection>>> getCollections(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/collections'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final collections = json['collections'] as List<dynamic>;
        return Right(List<Collection>.from(
            collections.map((e) => Collection.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, CollectionWithRelated>> getCollection(
    String collectionId, {
    RelatedCollectionsType? withRelated,
  }) {
    return _request(
      makeRequest: () {
        final query = withRelated == null ? '' : '?related=${withRelated.name}';
        return http.get(
          Uri.parse('$_urlBase/collections/$collectionId$query'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(CollectionWithRelated.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, List<KnownContactProfile>>> getKnownContactProfiles(
    List<String> phoneNumbers,
  ) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account/contacts'),
          headers: _headers,
          body: jsonEncode({'phoneNumbers': phoneNumbers}),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final list = json['knownContactProfiles'] as List<dynamic>;
        return Right(List<KnownContactProfile>.from(
            list.map((e) => KnownContactProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<SimpleProfile>>> getBlockedUsers() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/account/blocked_users'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return Right(List<SimpleProfile>.from(
            list.map((e) => SimpleProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, void>> blockUser(String blockUid) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/account/blocked_users/$blockUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> unblockUser(String unblockUid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/account/blocked_users/$unblockUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, String>> updateLocation(
      double latitude, double longitude) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account/location'),
          headers: _headers,
          body: jsonEncode({
            'latitude': latitude,
            'longitude': longitude,
          }),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(json['locationName'] ?? '');
      },
    );
  }

  static Future<Either<ApiError, void>> rejectCall(
    String uid,
    String rid,
    String authToken,
  ) {
    return _staticRequest(
      makeRequest: () {
        return http.post(
          // TODO: This imports from main.dart, this class should not be tied to main.dart
          Uri.parse('$urlBase/calls/$rid/reject'),
          headers: {
            ..._headers,
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'uid': uid}),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, T>> _requestStreamedResponseAsFuture<T>({
    required Future<http.StreamedResponse> Function() makeRequest,
    required Either<ApiError, T> Function(http.Response response) handleSuccess,
  }) async {
    return _request(
      makeRequest: () async => http.Response.fromStream(await makeRequest()),
      handleSuccess: handleSuccess,
    );
  }

  Future<Either<ApiError, T>> _request<T>({
    required Future<http.Response> Function() makeRequest,
    required Either<ApiError, T> Function(http.Response response) handleSuccess,
  }) async {
    // FirebaseAuth.instance.idTokenChanges does not seem to fire without calling User.getIdToken() first
    // TODO: Can we be notified of an expired token without using it first?
    //  this class should not be tied to Firebase
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken != null) {
      authToken = idToken;
    }

    return _staticRequest<T>(
        makeRequest: makeRequest, handleSuccess: handleSuccess);
  }

  static Future<Either<ApiError, T>> _staticRequest<T>({
    required Future<http.Response> Function() makeRequest,
    required Either<ApiError, T> Function(http.Response response) handleSuccess,
  }) async {
    try {
      final response = await makeRequest();
      if (response.statusCode != 200) {
        log(
          '${response.request?.method} ${response.request?.url}',
          name: 'API',
        );
      }
      if (response.statusCode == 200) {
        return handleSuccess(response);
      } else if (response.statusCode == 400) {
        log('400 Bad request', name: 'API', error: response.body);
        return const Left(ApiClientError(ClientErrorBadRequest()));
      } else if (response.statusCode == 401) {
        log('401 Unauthorized', name: 'API', error: response.body);
        return const Left(ApiClientError(ClientErrorUnauthorized()));
      } else if (response.statusCode == 403) {
        log('403 Forbidden', name: 'API', error: response.body);
        return const Left(ApiClientError(ClientErrorForbidden()));
      } else if (response.statusCode == 404) {
        log('404 Not found', name: 'API', error: response.body);
        return const Left(ApiClientError(ClientErrorNotFound()));
      } else if (response.statusCode == 409) {
        log('409 Conflict', name: 'API', error: response.body);
        return const Left(ApiClientError(ClientErrorConflict()));
      } else if (response.statusCode == 500) {
        log('500 Internal server error', name: 'API', error: response.body);
        return const Left(_ApiServerError(_ServerError()));
      } else {
        throw response;
      }
    } on SocketException catch (e) {
      log('SocketException', name: 'API', error: e);
      return const Left(_ApiNetworkError(_ConnectionFailed()));
    } catch (e) {
      rethrow;
    }
  }
}

final collectionReadyProvider =
    StateNotifierProvider<CollectionReadyStateNotifier, String?>(
        (ref) => CollectionReadyStateNotifier(null));

class CollectionReadyStateNotifier extends StateNotifier<String?> {
  CollectionReadyStateNotifier(super.state);

  void collectionId(String collectionId) => state = collectionId;
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError.network(NetworkError error) = _ApiNetworkError;
  const factory ApiError.client(ClientError error) = ApiClientError;
  const factory ApiError.server(ServerError error) = _ApiServerError;
}

@freezed
class NetworkError with _$NetworkError {
  const factory NetworkError.connectionFailed() = _ConnectionFailed;
}

@freezed
class ClientError with _$ClientError {
  const factory ClientError.badRequest() = ClientErrorBadRequest;
  const factory ClientError.unauthorized() = ClientErrorUnauthorized;
  const factory ClientError.notFound() = ClientErrorNotFound;
  const factory ClientError.forbidden() = ClientErrorForbidden;
  const factory ClientError.conflict() = ClientErrorConflict;
}

@freezed
class ServerError with _$ServerError {
  const factory ServerError.serverError() = _ServerError;
}

@freezed
class AccountCreationResult with _$AccountCreationResult {
  const factory AccountCreationResult({
    required bool created,
    required Profile profile,
  }) = _AccountCreationResult;

  factory AccountCreationResult.fromJson(Map<String, dynamic> json) =>
      _$AccountCreationResultFromJson(json);
}

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String uid,
    required String name,
    int? age,
    required Gender gender,
    required String photo,
    String? audio,
    required Collection collection,
    @Default([]) List<String> mutualFriends,
    @Default(0) int friendCount,
  }) = _Profile;

  // Private constructor required for adding methods
  const Profile._();

  SimpleProfile toSimpleProfile() {
    return SimpleProfile(
      uid: uid,
      name: name,
      photo: photo,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

@freezed
class SimpleProfile with _$SimpleProfile {
  const factory SimpleProfile({
    required String uid,
    required String name,
    required String photo,
  }) = _SimpleProfile;

  factory SimpleProfile.fromJson(Map<String, dynamic> json) =>
      _$SimpleProfileFromJson(json);
}

@freezed
class DiscoverProfile with _$DiscoverProfile {
  const factory DiscoverProfile({
    required Profile profile,
    required bool online,
  }) = _DiscoverProfile;

  factory DiscoverProfile.fromJson(Map<String, dynamic> json) =>
      _$DiscoverProfileFromJson(json);
}

@freezed
class ProfileWithCollections with _$ProfileWithCollections {
  const factory ProfileWithCollections({
    required Profile profile,
    required List<Collection> collections,
  }) = _ProfileWithCollections;

  factory ProfileWithCollections.fromJson(Map<String, dynamic> json) =>
      _$ProfileWithCollectionsFromJson(json);
}

enum Gender { male, female, nonBinary }

@freezed
class KnownContactProfile with _$KnownContactProfile {
  const factory KnownContactProfile({
    required Profile profile,
    required String phoneNumber,
  }) = _KnownContactProfile;

  factory KnownContactProfile.fromJson(Map<String, dynamic> json) =>
      _$KnownContactProfileFromJson(json);
}

@freezed
class DiscoverPage with _$DiscoverPage {
  const factory DiscoverPage({
    required List<DiscoverProfile> profiles,
    required double nextMinRadius,
    required int nextPage,
  }) = _DiscoverPage;

  factory DiscoverPage.fromJson(Map<String, dynamic> json) =>
      _$DiscoverPageFromJson(json);
}

@freezed
class Photo3d with _$Photo3d {
  const factory Photo3d({
    required String url,
    required String depthUrl,
  }) = _Photo3d;

  factory Photo3d.fromJson(Map<String, dynamic> json) =>
      _$Photo3dFromJson(json);
}

@freezed
class Collection with _$Collection {
  const factory Collection({
    required String collectionId,
    required String uid,
    required DateTime date,
    required CollectionState state,
    required List<Photo3d> photos,
  }) = _Collection;

  factory Collection.fromJson(Map<String, dynamic> json) =>
      _$CollectionFromJson(json);
}

enum CollectionState { processing, ready }

@freezed
class CollectionWithRelated with _$CollectionWithRelated {
  const factory CollectionWithRelated({
    required Collection collection,
    required List<Collection> related,
  }) = _CollectionWithRelated;

  factory CollectionWithRelated.fromJson(Map<String, dynamic> json) =>
      _$CollectionWithRelatedFromJson(json);
}

enum RelatedCollectionsType { user }

@freezed
class Chatroom with _$Chatroom {
  const factory Chatroom({
    required Profile profile,
    @_DateTimeConverter() required DateTime lastUpdated,
    required ChatroomState state,
    required int unreadCount,
  }) = _Chatroom;

  factory Chatroom.fromJson(Map<String, dynamic> json) =>
      _$ChatroomFromJson(json);
}

class _DateTimeConverter implements JsonConverter<DateTime, String> {
  const _DateTimeConverter();

  @override
  DateTime fromJson(String value) => DateTime.parse(value);

  @override
  String toJson(DateTime dateTime) => dateTime.toIso8601String();
}

enum ChatroomState { invitation, pending, accepted }
