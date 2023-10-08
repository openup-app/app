import 'package:flutter/services.dart';

final denyLowerCaseInputFormatter =
    FilteringTextInputFormatter.deny(RegExp('[a-zá-ú]'));
