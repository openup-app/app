import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:openup/api/lobby/lobby_api.dart';
import 'package:openup/api/users/connection.dart';
import 'package:openup/api/users/preferences.dart';
import 'package:openup/api/users/profile.dart';
import 'package:openup/api/users/rekindle.dart';

part 'api.freezed.dart';

class Api {
  final _headers = {
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

  Future<Either<ApiError, void>> createUser({
    required String uid,
    required DateTime birthday,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid'),
          headers: _headers,
          body: jsonEncode({
            'birthday': birthday.toIso8601String(),
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
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

  Future<Either<ApiError, bool>> checkBirthday({
    required String phone,
    required DateTime birthday,
  }) async {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/any/check_birthday'),
          headers: _headers,
          body: jsonEncode({
            'phone': phone,
            'birthday': birthday.toIso8601String(),
          }),
        );
      },
      handleSuccess: (response) {
        return Right(jsonDecode(response.body)['success'] == true);
      },
    );
  }

  Future<Either<ApiError, bool>> getOnboarded(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/onboarded'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(jsonDecode(response.body)['onboarded'] == true);
      },
    );
  }

  Future<Either<ApiError, void>> updateOnboarded(String uid, bool onboarded) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/onboarded'),
          headers: _headers,
          body: jsonEncode({'onboarded': onboarded}),
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

  Future<Either<ApiError, String>> updateProfileGalleryPhoto(
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
        return Right(json['url']);
      },
    );
  }

  Future<Either<ApiError, void>> deleteProfileGalleryPhoto(
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

  Future<Either<ApiError, Preferences>> getFriendsPreferences(String uid) =>
      _getPreferences(uid, Purpose.friends);

  Future<Either<ApiError, Preferences>> getDatingPreferences(String uid) =>
      _getPreferences(uid, Purpose.dating);

  Future<Either<ApiError, Preferences>> _getPreferences(
    String uid,
    Purpose purpose,
  ) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/preferences/${purpose.name}'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(Preferences.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, Attributes>> getAttributes(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/attributes'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        return Right(Attributes.fromJson(jsonDecode(response.body)));
      },
    );
  }

  Future<Either<ApiError, void>> updateAttributes(
    String uid,
    Attributes attributes,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/attributes'),
          headers: _headers,
          body: jsonEncode(attributes.toJson()),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> updateFriendsPreferences(
          String uid, Preferences preferences) =>
      _updatePreferences(uid, preferences, Purpose.friends);

  Future<Either<ApiError, void>> updateDatingPreferences(
          String uid, Preferences preferences) =>
      _updatePreferences(uid, preferences, Purpose.dating);

  Future<Either<ApiError, void>> _updatePreferences(
    String uid,
    Preferences preferences,
    Purpose purpose,
  ) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/users/$uid/preferences/${purpose.name}'),
          headers: _headers,
          body: jsonEncode(preferences.toJson()),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<Rekindle>>> getRekindles(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/users/$uid/rekindles'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final rekindles =
            List<Rekindle>.from(list.map((e) => Rekindle.fromJson(e)));
        return Right(rekindles);
      },
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
    String? messagingToken,
    String? voipToken,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/users/$uid/notification_tokens'),
          headers: _headers,
          body: jsonEncode({
            if (messagingToken != null) ...{'messaging_token': messagingToken},
            if (voipToken != null) ...{'voip_token': voipToken},
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

  Future<Either<ApiError, void>> contactUs(
      {required String uid, required String message}) {
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

  Future<Either<ApiError, T>> _request<T>({
    required Future<http.Response> Function() makeRequest,
    required Either<ApiError, T> Function(http.Response response) handleSuccess,
  }) async {
    try {
      final response = await makeRequest();
      if (response.statusCode == 200) {
        return handleSuccess(response);
      } else if (response.statusCode == 400) {
        return const Left(_ApiClientError(_BadRequest()));
      } else if (response.statusCode == 401) {
        return const Left(_ApiClientError(_Unauthorized()));
      } else if (response.statusCode == 403) {
        return const Left(_ApiClientError(_Forbidden()));
      } else if (response.statusCode == 404) {
        return const Left(_ApiClientError(_NotFound()));
      } else if (response.statusCode == 500) {
        return const Left(_ApiServerError(_ServerError()));
      } else {
        throw response;
      }
    } catch (e) {
      rethrow;
    }
  }
}

@freezed
class ApiError with _$ApiError {
  const factory ApiError.network(NetworkError error) = _ApiNetworkError;
  const factory ApiError.client(ClientError error) = _ApiClientError;
  const factory ApiError.server(ServerError error) = _ApiServerError;
}

@freezed
class NetworkError with _$NetworkError {
  const factory NetworkError.connectionFailed() = _ConnectionFailed;
}

@freezed
class ClientError with _$ClientError {
  const factory ClientError.badRequest() = _BadRequest;
  const factory ClientError.unauthorized() = _Unauthorized;
  const factory ClientError.notFound() = _NotFound;
  const factory ClientError.forbidden() = _Forbidden;
}

@freezed
class ServerError with _$ServerError {
  const factory ServerError.serverError() = _ServerError;
}
