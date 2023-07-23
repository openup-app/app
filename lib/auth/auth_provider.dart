import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:openup/api/user_state.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'auth_provider.freezed.dart';

final authProvider =
    StateNotifierProvider.autoDispose<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(
    api: ref.read(apiProvider),
    mixpanel: ref.read(mixpanelProvider),
  );
});

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Api api;
  final Mixpanel mixpanel;

  int? _forceResendingToken;
  User? _user;
  StreamSubscription? _idTokenChangesSubscription;

  static AuthState _initialState() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null
        ? const AuthState.guest()
        : AuthState.signedIn(user.uid);
  }

  AuthStateNotifier({
    required this.api,
    required this.mixpanel,
  }) : super(_initialState()) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _refreshAuthToken(user).then((token) {
        if (token != null) {
          api.authToken = token;
        }
      });
    }

    // Logging in/out triggers
    _idTokenChangesSubscription =
        FirebaseAuth.instance.idTokenChanges().listen(_onIdTokenChange);
  }

  @override
  void dispose() {
    _idTokenChangesSubscription?.cancel();
    super.dispose();
  }

  void deleteHangingAuthAccount() async {
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Sentry.captureMessage('User has created an account but not onboarded');
      }
    }
  }

  Future<String?> _refreshAuthToken(User user) async {
    for (var retryAttempt = 0; retryAttempt < 3; retryAttempt++) {
      debugPrint('FirebaseAuth getIdToken attempt $retryAttempt');
      try {
        return user.getIdToken(true);
      } on FirebaseAuthException catch (e) {
        debugPrint('FirebaseAuth error ${e.code}');
        if (e.code == 'user-not-found') {
          return null;
        } else if (e.code == 'unknown') {
          // Retry
          debugPrint('FirebaseAuth unknown error, retrying');
          await Future.delayed(const Duration(milliseconds: 300));
          continue;
        } else {
          rethrow;
        }
      }
    }
    return null;
  }

  void _onIdTokenChange(User? user) {
    final oldUser = _user;
    _user = user;
    final wasLoggedIn = oldUser != null;
    final loggedIn = user != null;
    final loginChange = wasLoggedIn != loggedIn;
    if (loginChange) {
      if (user != null) {
        mixpanel.identify(user.uid);
        Sentry.configureScope(
            (scope) => scope.setUser(SentryUser(id: user.uid)));
        state = _SignedIn(user.uid);
        _refreshAuthToken(user).then((token) {
          if (token != null) {
            api.authToken = token;
          }
        });
      } else {
        mixpanel.reset();
        Sentry.configureScope((scope) => scope.setUser(null));
        state = const _Guest();
      }
    }
  }

  Future<SendCodeResult> sendVerificationCode(String phoneNumber) async {
    mixpanel.track("signup_submit_phone");
    final completer = Completer<SendCodeResult>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete(const _Verified());
        } catch (e) {
          completer.complete(const _Error(SendCodeError.credentialFailure));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          completer.complete(const _Error(SendCodeError.invalidPhoneNumber));
        } else if (e.code == 'network-request-failed') {
          completer.complete(const _Error(SendCodeError.networkError));
        } else {
          Sentry.captureException(e);
          completer.complete(const _Error(SendCodeError.failure));
        }
      },
      codeSent: (verificationId, forceResendingToken) async {
        mixpanel.track("signup_code_sent");
        _forceResendingToken = forceResendingToken;
        completer.complete(_CodeSent(verificationId));
      },
      codeAutoRetrievalTimeout: (verificationId) {
        // Android SMS auto-fill failed, nothing to do
        debugPrint('Code auto retrieval timeout');
      },
    );
    return completer.future;
  }

  Future<AuthResult> authenticate({
    required String verificationId,
    required String smsCode,
  }) async {
    mixpanel.track("sign_up_submit_phone_verification");

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      return AuthResult.success;
    } on FirebaseAuthException catch (e, s) {
      if (e.code == 'invalid-verification-code') {
        return AuthResult.invalidCode;
      } else if (e.code == 'quota-exceeded') {
        return AuthResult.quotaExceeded;
      }
      Sentry.captureException(e, stackTrace: s);
      return AuthResult.failure;
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      return AuthResult.failure;
    }
  }
}

@freezed
class SendCodeResult with _$SendCodeResult {
  const factory SendCodeResult.codeSent(String verificationId) = _CodeSent;
  const factory SendCodeResult.verified() = _Verified;
  const factory SendCodeResult.error(SendCodeError error) = _Error;
}

enum SendCodeError {
  credentialFailure,
  invalidPhoneNumber,
  networkError,
  failure,
}

enum AuthResult { success, invalidCode, quotaExceeded, failure }

@freezed
class AuthState with _$AuthState {
  const factory AuthState.guest() = _Guest;
  const factory AuthState.signedIn(String uid) = _SignedIn;
}
