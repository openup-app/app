import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/api/api.dart';

final mixpanelProvider =
    Provider<Mixpanel>((ref) => throw 'Mixpanel is uninitialized');

final analyticsProvider =
    Provider<Analytics>((ref) => throw 'Uninitialized provider');

class Analytics {
  final Mixpanel _mixpanel;
  final FirebaseAnalytics _firebaseAnalytics;

  const Analytics({
    required Mixpanel mixpanel,
    required FirebaseAnalytics firebaseAnalytics,
  })  : _mixpanel = mixpanel,
        _firebaseAnalytics = firebaseAnalytics;

  void trackSigninEmailSuccess(String providerName) => _track(
        'signin_email_success',
        properties: {'provider': providerName},
      );

  void trackSigninEmailFailure(String providerName) => _track(
        'signin_email_failure',
        properties: {'provider': providerName},
      );

  void trackWaitlistRequestGlamourShotNotification() =>
      _track('waitlist_request_glamour_shot_notification');

  void trackAfterPartyProcessingRequestGlamourShotNotification() =>
      _track('after_party_processing_glamour_shot_notification');

  void trackAfterPartyRequestNextEventNotification() =>
      _track('after_party_request_next_event_notification');

  void trackSignupSubmitPhone() => _track('signup_submit_phone');

  void trackSignupCodeSent() => _track('signup_code_sent');

  void trackSignupSubmitPhoneVerification() =>
      _track('signup_submit_phone_verification');

  void trackSignupVerified() => _track('signup_verified');

  void trackSignupSubmitAge() => _track('signup_submit_age');

  void trackSignupSubmitAudio() => _track('signup_submit_audio');

  void trackSignupSubmitGender() => _track('signup_submit_gender');

  void trackSignupSubmitName() => _track('signup_submit_name');

  void trackSignupGrantPermissions() => _track('signup_grant_permissions');

  void trackSignupGrantOnlyLocationPermission() =>
      _track('signup_grant_only_location_permission');

  void trackSignupSubmitPhotos() => _track('signup_submit_photos');

  void trackCreateAccount() => _track(
        'create_account',
        firebaseSpecialEvent: () =>
            _firebaseAnalytics.logSignUp(signUpMethod: 'phone'),
      );

  void trackUpdateName({required String oldName, required String newName}) =>
      _track(
        'update_name',
        properties: {
          'oldName': oldName,
          'newName': newName,
        },
      );

  void trackGalleryReplacePhoto() => _track('gallery_replace_photo');

  void trackGalleryDeletePhoto() => _track('gallery_delete_photo');

  void trackChangePhoneSubmitPhone() => _track('change_phone_submit_phone');

  void trackChangePhoneCodeSent() => _track('change_phone_code_sent');

  void trackChangePhoneSubmitVerification() =>
      _track('change_phone_submit_phone_verification');

  void trackChangePhoneVerified() => _track('change_phone_verified');

  void trackUpdateAudioBio() => _track('update_audio_bio');

  void trackDeleteAccount() => _track('delete_account');

  void trackLogin() => _track(
        'login',
        firebaseSpecialEvent: () =>
            _firebaseAnalytics.logLogin(loginMethod: 'phone'),
      );

  void trackSendMessage() => _track('send_message');

  void trackViewMiniProfile() => _track('view_mini_profile');

  void trackViewFullProfile() => _track('view_full_profile');

  void trackUpdateVisibility(LocationVisibility visibility) => _track(
        'update_location_visibility',
        properties: {
          'visibility': visibility.name,
        },
      );

  void trackDeleteFriend() => _track('delete_friend');

  void trackShareProfile() => _track('share_profile');

  void trackSignOut() => _track('sign_out');

  void setUserId(String id) {
    _mixpanel.identify(id);
    _firebaseAnalytics.setUserId(id: id);
  }

  void setUserProperty(String key, dynamic value) {
    _mixpanel.getPeople().set(key, value);
    _firebaseAnalytics.setUserProperty(name: key, value: value.toString());
  }

  void resetUser() {
    _mixpanel.reset();
    _firebaseAnalytics.setUserId(id: null);
  }

  void _track(
    String key, {
    Map<String, Object>? properties,
    void Function()? firebaseSpecialEvent,
  }) {
    _mixpanel.track(key, properties: properties);
    if (firebaseSpecialEvent == null) {
      _firebaseAnalytics.logEvent(name: key, parameters: properties);
    } else {
      firebaseSpecialEvent();
    }
  }
}
