import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/auth/auth_provider.dart';

part 'waitlist_provider.freezed.dart';

final waitlistProvider = Provider.autoDispose<WaitlistUser?>((ref) {
  return ref.watch(authProvider.select<WaitlistUser?>((s) {
    return s.map(
      guest: (_) => null,
      signedIn: (signedIn) {
        final uid = signedIn.uid;
        final emailAddress = signedIn.emailAddress;
        if (emailAddress != null && emailAddress.isNotEmpty) {
          return WaitlistUser(
            uid: uid,
            email: emailAddress,
          );
        }
        return null;
      },
    );
  }));
}, dependencies: [authProvider]);

@freezed
class WaitlistUser with _$WaitlistUser {
  const factory WaitlistUser({
    required String uid,
    required String email,
  }) = _WaitlistUser;
}
