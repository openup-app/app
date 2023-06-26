import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final keyValueStoreProvider = Provider<SharedPreferences>(
    (ref) => throw 'Key value store is uninitialized');
