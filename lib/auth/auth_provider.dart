import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:openup/analytics/analytics.dart';
import 'package:openup/api/api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'auth_provider.freezed.dart';

final authProvider =
    StateNotifierProvider.autoDispose<AuthStateNotifier, AuthState>(
        (ref) => throw 'Uninitialized provider');

class AuthStateNotifier extends StateNotifier<AuthState> {
  final Api api;
  final Analytics analytics;
  final _googleSignIn = GoogleSignIn();

  int? _forceResendingToken;
  User? _user;
  StreamSubscription? _idTokenChangesSubscription;

  static AuthState _initialState() {
    final user = FirebaseAuth.instance.currentUser;
    return user == null
        ? const AuthState.guest()
        : AuthState.signedIn(
            uid: user.uid,
            phoneNumber: user.phoneNumber,
            emailAddress: user.email,
          );
  }

  AuthStateNotifier({
    required this.api,
    required this.analytics,
  }) : super(_initialState()) {
    _init();
  }

  void _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _refreshAuthToken(user);
      if (!mounted) {
        return;
      }

      if (token != null) {
        api.authToken = token;
      }
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

  Future<void> signOut() => FirebaseAuth.instance.signOut();

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

  void _onIdTokenChange(User? user) async {
    final oldUser = _user;
    _user = user;
    final wasLoggedIn = oldUser != null;
    final loggedIn = user != null;
    final loginChange = wasLoggedIn != loggedIn;
    if (loginChange) {
      if (user != null) {
        analytics.setUserId(user.uid);
        Sentry.configureScope(
            (scope) => scope.setUser(SentryUser(id: user.uid)));
        state = AuthSignedIn(
          uid: user.uid,
          phoneNumber: user.phoneNumber,
          emailAddress: user.email,
        );
        final token = await _refreshAuthToken(user);
        if (!mounted) {
          return;
        }
        state = state.map(
          guest: (guest) => guest,
          signedIn: (signedIn) => signedIn.copyWith(token: token),
        );
        if (token != null) {
          api.authToken = token;
        }
      } else {
        analytics.resetUser();
        Sentry.configureScope((scope) => scope.setUser(null));
        state = const _Guest();
      }
    }

    if (wasLoggedIn && loggedIn && oldUser.phoneNumber != user.phoneNumber) {
      state = AuthState.signedIn(
        uid: user.uid,
        phoneNumber: user.phoneNumber,
        emailAddress: user.email,
      );
    }
  }

  Future<AuthResult?> signInWithGoogle() async {
    late final GoogleSignInAccount account;
    try {
      final result = await _googleSignIn.signIn();
      if (result == null) {
        return null;
      }
      account = result;
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed') {
        return AuthResult.failure;
      }
    }
    final authentication = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: authentication.idToken,
      accessToken: authentication.accessToken,
    );
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = result.user;
    if (user != null) {
      return AuthResult.success;
    } else {
      return AuthResult.failure;
    }
  }

  Future<AuthResult?> signInWithApple() async {
    final appleProvider = AppleAuthProvider()..addScope('email');
    final result =
        await FirebaseAuth.instance.signInWithProvider(appleProvider);
    final user = result.user;
    if (user != null) {
      return AuthResult.success;
    } else {
      return AuthResult.failure;
    }
  }

  Future<SendCodeResult> signInWithPhoneNumber(String phoneNumber) async {
    analytics.trackSignupSubmitPhone();
    final completer = Completer<SendCodeResult>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: _forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          completer.complete(const _Verified());
        } catch (e, s) {
          debugPrint(e.toString());
          Sentry.captureException(e, stackTrace: s);
          completer.complete(const _Error(SendCodeError.failure));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          completer.complete(const _Error(SendCodeError.invalidPhoneNumber));
        } else if (e.code == 'network-request-failed') {
          completer.complete(const _Error(SendCodeError.networkError));
        } else if (e.code == 'too-many-requests') {
          completer.complete(const _Error(SendCodeError.tooManyRequests));
        } else if (e.code == 'quota-exceeded') {
          Sentry.captureException(e);
          completer.complete(const _Error(SendCodeError.quotaExceeded));
        } else {
          debugPrint(e.code);
          Sentry.captureException(e);
          completer.complete(const _Error(SendCodeError.failure));
        }
      },
      codeSent: (verificationId, forceResendingToken) async {
        analytics.trackSignupCodeSent();
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

  Future<SendCodeResult> updatePhoneNumber(String newPhoneNumber) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.value(const _Error(SendCodeError.failure));
    }

    analytics.trackChangePhoneSubmitPhone();
    final completer = Completer<SendCodeResult>();
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: newPhoneNumber,
      verificationCompleted: (credential) async {
        try {
          await user.updatePhoneNumber(credential);
          if (mounted) {
            completer.complete(const SendCodeResult.verified());
          }
        } catch (e, s) {
          debugPrint(e.toString());
          Sentry.captureException(e, stackTrace: s);
          completer.complete(const _Error(SendCodeError.failure));
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          completer.complete(const _Error(SendCodeError.invalidPhoneNumber));
        } else if (e.code == 'network-request-failed') {
          completer.complete(const _Error(SendCodeError.networkError));
        } else if (e.code == 'too-many-requests') {
          completer.complete(const _Error(SendCodeError.tooManyRequests));
        } else if (e.code == 'quota-exceeded') {
          Sentry.captureException(e);
          completer.complete(const _Error(SendCodeError.quotaExceeded));
        } else {
          debugPrint(e.code);
          Sentry.captureException(e);
          completer.complete(const _Error(SendCodeError.failure));
        }
      },
      codeSent: (verificationId, forceResendingToken) async {
        analytics.trackChangePhoneCodeSent();
        _forceResendingToken = forceResendingToken;
        completer.complete(_CodeSent(verificationId));
      },
      forceResendingToken: _forceResendingToken,
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
    analytics.trackSignupSubmitPhoneVerification();

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
      } else if (e.code == 'invalid-verification-id') {
        return AuthResult.invalidId;
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

  Future<AuthResult> authenticatePhoneChange({
    required String verificationId,
    required String smsCode,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Future.value(AuthResult.failure);
    }

    analytics.trackChangePhoneSubmitVerification();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await user.updatePhoneNumber(credential);
      analytics.trackChangePhoneVerified();
      return AuthResult.success;
    } on FirebaseAuthException catch (e, s) {
      if (e.code == 'invalid-verification-code') {
        return AuthResult.invalidCode;
      } else if (e.code == 'invalid-verification-id') {
        return AuthResult.invalidId;
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
  tooManyRequests,
  quotaExceeded,
  failure,
}

enum AuthResult { success, invalidCode, invalidId, quotaExceeded, failure }

@freezed
class AuthState with _$AuthState {
  const factory AuthState.guest() = _Guest;
  const factory AuthState.signedIn({
    required String uid,
    required String? phoneNumber,
    required String? emailAddress,
    @Default(null) String? token,
  }) = AuthSignedIn;
}
