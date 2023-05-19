import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';

final mixpanelProvider =
    Provider<Mixpanel>((ref) => throw 'Mixpanel is uninitialized');
