import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openup/api/chat/chat_api.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/main.dart';
import 'package:openup/util/location_service.dart';

part 'api.freezed.dart';
part 'api.g.dart';

class Api {
  static final _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

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

  Future<Either<ApiError, bool>> createUser({
    required String uid,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(jsonDecode(response.body)['created'] == true);
      },
    );
  }

  Future<Either<ApiError, void>> deleteUser(String uid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid'),
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
          Uri.parse('$_urlBase/users/$uid/profile'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(Profile.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, void>> updateProfile(String uid, Profile profile) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/profile'),
          headers: _headers,
          body: jsonEncode(profile.toJson()),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, Profile>> updateProfileGalleryPhoto(
    String uid,
    Uint8List photo,
    int index,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/profile/gallery/$index'),
          headers: {
            ..._headers,
            'Content-Type': 'application/octet-stream',
          },
          body: photo,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, Profile>> deleteProfileGalleryPhoto(
    String uid,
    int index,
  ) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid/profile/gallery/$index'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, String>> updateProfileAudio(
    String uid,
    Uint8List audio,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/profile/audio'),
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

  Future<Either<ApiError, void>> deleteProfileAudio(String uid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid/profile/audio'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> addConnectionRequest(
    String uid,
    String otherUid,
  ) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$otherUid/connection_requests'),
          headers: _headers,
          body: jsonEncode({'uid': uid}),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<Connection>>> getConnections(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/connections'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final connections =
            List<Connection>.from(list.map((e) => Connection.fromJson(e)));
        return Right(connections);
      },
    );
  }

  Future<Either<ApiError, List<String>>> getConnectionUids(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/connection_uids'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final uids = List<String>.from(json['uids'] ?? []);
        return Right(uids);
      },
    );
  }

  Future<Either<ApiError, List<Connection>>> deleteConnection(
    String uid,
    String deleteUid,
  ) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid/connections/$deleteUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final connections =
            List<Connection>.from(list.map((e) => Connection.fromJson(e)));
        return Right(connections);
      },
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

  Future<Either<ApiError, void>> addNotificationTokens(
    String uid, {
    String? fcmMessagingAndVoipToken,
    String? fcmMessagingToken,
    String? apnVoipToken,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid/notification_tokens'),
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
              if (fcmMessagingToken != null)
                {
                  'token': fcmMessagingToken,
                  'messaging': true,
                  'voip': false,
                  'service': 'fcm',
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

  Future<Either<ApiError, List<ChatMessage>>> getMessages(
    String chatroomId, {
    DateTime? startDate,
    int limit = 10,
  }) async {
    return _request(
      makeRequest: () {
        final query =
            '${startDate == null ? '' : 'startDate=${startDate.toIso8601String()}&'}limit=$limit';
        return http.get(
          Uri.parse('$_urlBase/chats/$chatroomId?$query'),
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
    String uid,
    String chatroomId,
    ChatType type,
    String content,
  ) async {
    final uri = Uri.parse('$_urlBase/chats/$chatroomId');
    switch (type) {
      case ChatType.emoji:
        return _request(
          makeRequest: () {
            return http.post(
              uri,
              headers: _headers,
              body: jsonEncode({
                'uid': uid,
                'type': type.name,
                'content': content,
              }),
            );
          },
          handleSuccess: (response) {
            return Right(ChatMessage.fromJson(jsonDecode(response.body)));
          },
        );
      case ChatType.image:
      case ChatType.video:
      case ChatType.audio:
        return _requestStreamedResponse(
          makeRequest: () async {
            final request = http.MultipartRequest('POST', uri);
            request.headers.addAll(_headers);
            request.fields['uid'] = uid;
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

  Future<Either<ApiError, Map<Topic, List<TopicParticipant>>>> getStatuses(
    String uid,
    bool nearby,
  ) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/statuses/${nearby ? 'nearby' : ''}'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = List.from(jsonDecode(response.body));
        final parsed = List<TopicParticipant>.from(list.map((e) {
          try {
            return TopicParticipant.fromJson(e);
          } catch (e) {
            debugPrint(e.toString());
            return null;
          }
        }).where((e) => e != null));
        final map = Map.fromEntries(
            Topic.values.map((e) => MapEntry(e, <TopicParticipant>[])));
        final topics =
            Map.fromEntries(Topic.values.map((e) => MapEntry(e.name, e)));
        for (final participant in parsed) {
          final topic = topics[participant.topic];
          if (topic != null) {
            map[topic]?.add(participant);
          }
        }
        return Right(map);
      },
    );
  }

  Future<Either<ApiError, Status?>> getStatus(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/status'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = _parseStatus(json);
        return Right(status);
      },
    );
  }

  Future<Either<ApiError, Status?>> updateStatus(
    String uid,
    Topic topic,
    Uint8List? audio,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/status/${topic.name}'),
          headers: {
            ..._headers,
            if (audio != null) ...{'Content-Type': 'application/octet-stream'}
          },
          body: audio,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = _parseStatus(json);
        return Right(status);
      },
    );
  }

  Status? _parseStatus(Map<String, dynamic> json) {
    final status = json['status'];
    if (status == null) {
      return null;
    }
    status['endTime'] = DateTime.now().toIso8601String();
    return Status.fromJson(status);
  }

  Future<Either<ApiError, void>> deleteStatus(String uid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid/status'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<SimpleProfile>>> getBlockedUsers(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/block'),
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

  Future<Either<ApiError, void>> blockUser(String uid, String blockUid) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid/block'),
          headers: _headers,
          body: jsonEncode({
            'blockUid': blockUid,
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> unblockUser(String uid, String unblockUid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/users/$uid/block/$unblockUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> updateLocation(String uid, LatLong location) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid/location'),
          headers: _headers,
          body: jsonEncode({
            'latitude': location.latitude,
            'longitude': location.longitude,
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
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

  Future<Either<ApiError, T>> _requestStreamedResponse<T>({
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
class Status with _$Status {
  const factory Status({
    required Topic topic,
    required String audioUrl,
    @Default("") String location,
    required DateTime endTime,
  }) = _Status;

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
}

enum Topic { lonely, friends, moved, sleep, bored, introvert }
