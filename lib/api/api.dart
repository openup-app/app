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
import 'package:openup/contacts/contacts_provider.dart';
import 'package:openup/main.dart';
import 'package:openup/notifications/notifications.dart';

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

  Future<void> updateWaitlist(
    String uid,
    String email,
    NotificationToken? notificationToken, {
    required WaitlistEvent event,
  }) {
    late final String? token;
    late final bool? voip;
    late final String? service;
    if (notificationToken == null) {
      token = null;
      voip = null;
      service = null;
    }
    notificationToken?.map(
      fcmMessagingAndVoip: (fcmMessagingAndVoip) {
        token = fcmMessagingAndVoip.token;
        voip = true;
        service = 'fcm';
      },
      apnsMessaging: (apnsMessaging) {
        token = apnsMessaging.token;
        voip = false;
        service = 'apns';
      },
    );

    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/waitlist'),
          headers: _headers,
          body: jsonEncode({
            'uid': uid,
            'email': email,
            if (token != null && voip != null && service != null) ...{
              'token': {
                'token': token,
                'messaging': true,
                'voip': voip,
                'service': service,
              },
            },
            'event': event.name,
          }),
        );
      },
      handleSuccess: (_) => const Right(null),
    );
  }

  Future<Either<ApiError, Account>> createAccount(
    AccountCreationParams params,
  ) {
    final photos = params.photos;
    final audio = params.audio;
    final name = params.name;
    final age = params.age;
    final latLong = params.latLong;
    if (photos == null ||
        audio == null ||
        name == null ||
        age == null ||
        latLong == null) {
      return Future.value(const Left(ApiError.client(ClientErrorBadRequest())));
    }
    return _requestStreamedResponseAsFuture(
      makeRequest: () async {
        final uri = Uri.parse('$_urlBase/account');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        request.files.addAll([
          for (final photo in photos)
            await http.MultipartFile.fromPath('photos', photo.path),
          await http.MultipartFile.fromPath('audio', audio.path),
        ]);
        request.fields.addAll({
          'account': jsonEncode({
            'name': name,
            'age': age,
            'location': latLong,
          }),
        });
        return request.send();
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Account.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, Account>> getAccount() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/account'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Account.fromJson(json));
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

  Future<Either<ApiError, AppAvailability>> getAppAvailability() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/app_availability'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(AppAvailability.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, AccountState>> getAccountState() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/account_state'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(AccountState.fromJson(json));
      },
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
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
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

  Future<Either<ApiError, Profile>> updateProfileName(String uid, String name) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/profiles/$uid/name'),
          headers: _headers,
          body: jsonEncode({'name': name}),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, Profile>> updateProfileAudio(
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
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, Profile>> updateGalleryPhoto(
    String uid,
    int index,
    File photo,
  ) {
    return _request(
      makeRequest: () async {
        return http.put(
          Uri.parse('$_urlBase/profiles/$uid/gallery/$index'),
          headers: {
            ..._headers,
            'Content-Type': 'application/octet-stream',
          },
          body: await photo.readAsBytes(),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, Profile>> deleteGalleryPhoto(
    String uid,
    int index,
  ) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/profiles/$uid/gallery/$index'),
          headers: {..._headers},
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
      },
    );
  }

  Future<Either<ApiError, Profile>> updateProfileCollection({
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
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json['profile']));
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

  Future<Either<ApiError, void>> addNotificationToken(
    NotificationToken notificationToken,
  ) {
    late final String token;
    late final bool voip;
    late final String service;
    notificationToken.map(
      fcmMessagingAndVoip: (fcmMessagingAndVoip) {
        token = fcmMessagingAndVoip.token;
        voip = true;
        service = 'fcm';
      },
      apnsMessaging: (apnsMessaging) {
        token = apnsMessaging.token;
        voip = false;
        service = 'apns';
      },
    );

    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/accounts/notification_tokens'),
          headers: _headers,
          body: jsonEncode({
            'tokens': [
              {
                'token': token,
                'messaging': true,
                'voip': voip,
                'service': service,
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

  Future<Either<ApiError, void>> reportEvent({
    required String eventId,
  }) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/events/$eventId/reports'),
          headers: _headers,
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
        final json = jsonDecode(response.body);
        final chatrooms = json['chatrooms'] as List<dynamic>;
        return Right(List.from(chatrooms.map((e) => Chatroom.fromJson(e))));
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
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Chatroom.fromJson(json['chatroom']));
      },
    );
  }

  Future<Either<ApiError, List<Chatroom>>> deleteChatroom(
      String otherUid) async {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/chats/$otherUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final chatrooms = json['chatrooms'] as List<dynamic>;
        return Right(List.from(chatrooms.map((e) => Chatroom.fromJson(e))));
      },
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
        final json = jsonDecode(response.body);
        final messages = json['messages'] as List<dynamic>;
        return Right(List.from(messages.map((e) => ChatMessage.fromJson(e))));
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
            final json = jsonDecode(response.body);
            return Right(ChatMessage.fromJson(json['message']));
          },
        );
    }
  }

  Future<Either<ApiError, DiscoverResultsPage>> getDiscover({
    required Location location,
    Gender? gender,
    bool? debug,
  }) {
    return _request(
      makeRequest: () {
        final locationQuery =
            'lat=${location.latLong.latitude}&long=${location.latLong.longitude}&radius=${location.radius}';
        final genderQuery = gender == null ? null : 'gender=${gender.name}';
        final debugQuery = debug == null ? null : 'debug=$debug';
        return http.get(
          Uri.parse('$_urlBase/discover?${[
            locationQuery,
            genderQuery,
            debugQuery,
          ].where((q) => q != null).join('&')}'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(DiscoverResultsPage.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, Profile>> addFavorite(String otherUid) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/favorites/$otherUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, Profile>> removeFavorite(String otherUid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/favorites/$otherUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Profile.fromJson(json));
      },
    );
  }

  Future<Either<ApiError, List<Chatroom>>> declineInvitation(String otherUid) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/chats/$otherUid/decline'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final chatrooms = json['chatrooms'] as List<dynamic>;
        return Right(List.from(chatrooms.map((e) => Chatroom.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, Collection>> createCollection(
    List<String> photos, {
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

  Future<Either<ApiError, Event>> createEvent(EventSubmission submission) {
    final photoPath = submission.photo?.toFilePath();
    if (photoPath == null) {
      throw StateError('Event photo URI can not be null');
    }
    return _requestStreamedResponseAsFuture(
      makeRequest: () async {
        final uri = Uri.parse('$_urlBase/events');
        final request = http.MultipartRequest('POST', uri);
        request.headers.addAll(_headers);
        final photoFile = await http.MultipartFile.fromPath('photo', photoPath);
        request.files.add(photoFile);
        request.fields.addAll({
          'submission': jsonEncode(submission),
        });
        return request.send();
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Event.fromJson(json['event']));
      },
    );
  }

  Future<Either<ApiError, Event>> updateEvent(
    String eventId,
    EventSubmission submission,
  ) {
    String? photoPath;
    try {
      photoPath = submission.photo?.toFilePath();
    } catch (e) {
      // Nothing to do, photo not updated
    }
    return _requestStreamedResponseAsFuture(
      makeRequest: () async {
        final uri = Uri.parse('$_urlBase/events/$eventId');
        final request = http.MultipartRequest('PUT', uri);
        request.headers.addAll(_headers);
        http.MultipartFile? photoFile;
        if (photoPath != null) {
          photoFile = await http.MultipartFile.fromPath('photo', photoPath);
          request.files.add(photoFile);
        }
        request.fields.addAll({'submission': jsonEncode(submission.toJson())});
        return request.send();
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        return Right(Event.fromJson(json['event']));
      },
    );
  }

  Future<Either<ApiError, void>> deleteEvent(String eventId) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/events/$eventId'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, Event>> updateEventParticipation(
    String eventId,
    bool participating,
  ) {
    return _request(makeRequest: () {
      return http.put(
        Uri.parse('$_urlBase/events/$eventId/participants'),
        headers: _headers,
        body: jsonEncode({'participating': participating}),
      );
    }, handleSuccess: (response) {
      final json = jsonDecode(response.body);
      return Right(Event.fromJson(json['event']));
    });
  }

  Future<Either<ApiError, void>> viewEvent(String eventId) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/events/$eventId/view'),
          headers: _headers,
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, List<Event>>> getEvents(
    Location location, {
    DateTime? date,
  }) {
    return _request(
      makeRequest: () {
        final locationQuery =
            'lat=${location.latLong.latitude}&long=${location.latLong.longitude}&radius=${location.radius}';
        final dateQuery =
            date == null ? '' : '&date=${date.toLocal().toIso8601String()}';
        return http.get(
          Uri.parse('$_urlBase/events?$locationQuery$dateQuery'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final events = json['events'] as List<dynamic>;
        return Right(List.from(events.map((e) => Event.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<Event>>> getMyHostedEvents(String uid) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/events?host=$uid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final events = json['events'] as List<dynamic>;
        return Right(List.from(events.map((e) => Event.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<Event>>> getMyAttendingEvents() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/events?attending=true'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final events = json['events'] as List<dynamic>;
        return Right(List.from(events.map((e) => Event.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<SimpleProfile>>> getParticipantSimpleProfiles(
      String eventId) {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/events/$eventId/participants'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final events = json['participants'] as List<dynamic>;
        return Right(List.from(events.map((e) => SimpleProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<KnownContact>>> addContacts(
      List<Contact> contacts) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account/contacts'),
          headers: _headers,
          body: jsonEncode({
            'contacts': [
              for (final contact in contacts)
                {
                  'name': contact.name,
                  'phoneNumber': contact.phoneNumber,
                },
            ]
          }),
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final knownContacts = json['knownContacts'] as List<dynamic>;
        return Right(
            List.from(knownContacts.map((e) => KnownContact.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<KnownContact>>> getKnownContacts() {
    return _request(
      makeRequest: () {
        return http.get(
          Uri.parse('$_urlBase/account/contacts'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final knownContacts = json['knownContacts'] as List<dynamic>;
        return Right(
            List.from(knownContacts.map((e) => KnownContact.fromJson(e))));
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
        final json = jsonDecode(response.body);
        final blockedUsers = json['blockedUsers'] as List<dynamic>;
        return Right(
            List.from(blockedUsers.map((e) => SimpleProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<SimpleProfile>>> blockUser(String blockUid) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/account/blocked_users/$blockUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final blockedUsers = json['blockedUsers'] as List<dynamic>;
        return Right(
            List.from(blockedUsers.map((e) => SimpleProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, List<SimpleProfile>>> unblockUser(String unblockUid) {
    return _request(
      makeRequest: () {
        return http.delete(
          Uri.parse('$_urlBase/account/blocked_users/$unblockUid'),
          headers: _headers,
        );
      },
      handleSuccess: (response) {
        final json = jsonDecode(response.body);
        final blockedUsers = json['blockedUsers'] as List<dynamic>;
        return Right(
            List.from(blockedUsers.map((e) => SimpleProfile.fromJson(e))));
      },
    );
  }

  Future<Either<ApiError, void>> updateLocation(LatLong latLong) {
    return _request(
      makeRequest: () {
        return http.post(
          Uri.parse('$_urlBase/account/location'),
          headers: _headers,
          body: jsonEncode({
            'latitude': latLong.latitude,
            'longitude': latLong.longitude,
          }),
        );
      },
      handleSuccess: (response) => const Right(null),
    );
  }

  Future<Either<ApiError, void>> updateLocationVisibility(
      LocationVisibility visibility) {
    return _request(
      makeRequest: () {
        return http.put(
          Uri.parse('$_urlBase/account/location/visibility'),
          headers: _headers,
          body: jsonEncode({'visibility': visibility.name}),
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
    // TODO: Unify all id token fetches
    try {
      final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (idToken != null) {
        authToken = idToken;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'no-current-user') {
        // Ignore
      }
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

enum LocationVisibility { public, private }

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
class AccountCreationParams with _$AccountCreationParams {
  const factory AccountCreationParams({
    @Default(null) String? name,
    @Default(null) int? age,
    @Default(null) List<File>? photos,
    @Default(null) File? audio,
    @Default(null) LatLong? latLong,
  }) = _AccountCreationParams;

  const AccountCreationParams._();

  bool get valid =>
      nameValid && ageValid && photosValid && audioValid && latLong != null;

  bool get nameValid => name != null && name!.isNotEmpty;

  bool get ageValid => age != null && age! >= 17;

  bool get photosValid =>
      photos != null && photos!.whereType<File>().isNotEmpty;

  bool get audioValid => audio != null;
}

@freezed
class Account with _$Account {
  const factory Account({
    required Profile profile,
  }) = _Account;

  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);
}

@freezed
class AppAvailability with _$AppAvailability {
  const factory AppAvailability({
    required bool partyComplete,
    required bool appLocked,
    required List<String> sampleVideos,
  }) = _AppAvailability;

  factory AppAvailability.fromJson(Map<String, dynamic> json) =>
      _$AppAvailabilityFromJson(json);
}

@Freezed(unionKey: 'state', unionValueCase: FreezedUnionCase.none)
class AccountState with _$AccountState {
  const factory AccountState.account(Account account) = _AccountState;
  const factory AccountState.needsSignup(String video) = _NeedsSignup;
  const factory AccountState.none() = _None;

  factory AccountState.fromJson(Map<String, dynamic> json) =>
      _$AccountStateFromJson(json);
}

enum WaitlistEvent { glamourShotDeltaHouseHalloween2023, next }

@freezed
class Profile with _$Profile {
  const factory Profile({
    required String uid,
    required String name,
    int? age,
    required String photo,
    @_Base64Converter() required Uint8List photoThumbnail,
    required String audio,
    required List<String> gallery,
    required UserNamedLocation location,
    @Default([]) List<KnownContact> mutualContacts,
    @Default(0) int friendCount,
    @Default(null) LatLong? latLongOverride,
    @Default(false) hasSyncedContacts,
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
class UserLocation with _$UserLocation {
  const factory UserLocation({
    required LatLong latLong,
    required double radius,
    required LocationVisibility visibility,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);
}

@freezed
class UserNamedLocation with _$UserNamedLocation {
  const factory UserNamedLocation({
    required LatLong latLong,
    required String name,
  }) = _UserNamedLocation;

  factory UserNamedLocation.fromJson(Map<String, dynamic> json) =>
      _$UserNamedLocationFromJson(json);
}

@freezed
class Location with _$Location {
  const factory Location({
    required LatLong latLong,
    required double radius,
  }) = _Location;

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);
}

@freezed
class LatLong with _$LatLong {
  const factory LatLong({
    required double latitude,
    required double longitude,
  }) = _LatLong;

  factory LatLong.fromJson(Map<String, dynamic> json) =>
      _$LatLongFromJson(json);
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
class KnownContact with _$KnownContact {
  const factory KnownContact({
    required String uid,
    required String name,
    required String photo,
  }) = _KnownContact;

  factory KnownContact.fromJson(Map<String, dynamic> json) =>
      _$KnownContactFromJson(json);
}

@freezed
class DiscoverResultsPage with _$DiscoverResultsPage {
  const factory DiscoverResultsPage({
    required List<Profile> profiles,
  }) = _DiscoverResultsPage;

  factory DiscoverResultsPage.fromJson(Map<String, dynamic> json) =>
      _$DiscoverResultsPageFromJson(json);
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
    @_DateTimeConverter() required DateTime date,
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
    required ChatroomState inviteState,
    required int unreadCount,
  }) = _Chatroom;

  factory Chatroom.fromJson(Map<String, dynamic> json) =>
      _$ChatroomFromJson(json);
}

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String title,
    required HostDetails host,
    required EventLocation location,
    @_DateTimeConverter() required DateTime startDate,
    @_DateTimeConverter() required DateTime endDate,
    @_UriConverter() required Uri photo,
    required int price,
    required int views,
    required EventAttendance attendance,
    required String description,
    required EventParticipants participants,
    @Default(false) bool specialTbd,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

@freezed
class EventSubmission with _$EventSubmission {
  const factory EventSubmission({
    @Default('') String title,
    required EventLocation location,
    @_DateTimeConverter() required DateTime startDate,
    @_DateTimeConverter() required DateTime endDate,
    @Default(null) @_UriConverter() Uri? photo,
    @Default(0) int price,
    @Default(EventAttendance.limited(2)) EventAttendance attendance,
    @Default('') String description,
  }) = _EventSubmission;

  factory EventSubmission.fromJson(Map<String, dynamic> json) =>
      _$EventSubmissionFromJson(json);

  const EventSubmission._();

  Event toPreviewEvent(String hostUid, String hostName, String hostPhoto) {
    final photoUri = photo;
    if (photoUri == null) {
      throw 'Failed to create event preview';
    }
    return Event(
      id: '',
      title: title,
      host: HostDetails(
        uid: hostUid,
        name: hostName,
        photo: hostPhoto,
      ),
      location: location,
      startDate: startDate,
      endDate: endDate,
      photo: photoUri,
      price: price,
      views: 0,
      attendance: attendance,
      description: description,
      participants: EventParticipants(
        count: 1,
        uids: [hostUid],
      ),
    );
  }

  bool get valid => !(title.isEmpty ||
      location.name.isEmpty ||
      description.isEmpty ||
      photo == null);
}

@freezed
class EventLocation with _$EventLocation {
  const factory EventLocation({
    required LatLong latLong,
    required String name,
  }) = _EventLocation;

  factory EventLocation.fromJson(Map<String, dynamic> json) =>
      _$EventLocationFromJson(json);
}

@Freezed(unionKey: 'type')
class EventAttendance with _$EventAttendance {
  const factory EventAttendance.unlimited() = _UnlimitedAttendance;
  const factory EventAttendance.limited(int limit) = _LimitedAttendance;

  factory EventAttendance.fromJson(Map<String, dynamic> json) =>
      _$EventAttendanceFromJson(json);
}

@freezed
class EventParticipants with _$EventParticipants {
  const factory EventParticipants({
    required int count,
    required List<String> uids,
  }) = _EventParticipants;

  factory EventParticipants.fromJson(Map<String, dynamic> json) =>
      _$EventParticipantsFromJson(json);
}

@freezed
class HostDetails with _$HostDetails {
  const factory HostDetails({
    required String uid,
    required String name,
    required String photo,
  }) = _HostDetails;

  factory HostDetails.fromJson(Map<String, dynamic> json) =>
      _$HostDetailsFromJson(json);
}

class _DateTimeConverter implements JsonConverter<DateTime, String> {
  const _DateTimeConverter();

  @override
  DateTime fromJson(String value) => DateTime.parse(value);

  @override
  String toJson(DateTime dateTime) => dateTime.toIso8601String();
}

class _Base64Converter implements JsonConverter<Uint8List, String> {
  const _Base64Converter();

  @override
  Uint8List fromJson(String value) => base64Decode(value);

  @override
  String toJson(Uint8List data) => base64Encode(data);
}

class _UriConverter implements JsonConverter<Uri, String> {
  const _UriConverter();

  @override
  Uri fromJson(String value) => Uri.parse(value);

  @override
  String toJson(Uri data) => data.toString();
}

enum ChatroomState { invited, pending, accepted }
