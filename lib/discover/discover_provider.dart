import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openup/api/api.dart';

part 'discover_provider.freezed.dart';

final discoverActionProvider = StateProvider<DiscoverAction?>((ref) => null);

@freezed
class DiscoverAction with _$DiscoverAction {
  const factory DiscoverAction.viewProfile(DiscoverProfile profile) =
      _ViewProfile;
}
