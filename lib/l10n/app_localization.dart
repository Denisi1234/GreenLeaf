import 'package:flutter/widgets.dart';
import 'app_strings.dart';

extension AppLocalization on BuildContext {
  AppStrings get strings => AppStrings.of(this);

  String tr(String key, {Map<String, Object?> args = const {}}) =>
      strings.text(key, args: args);
}
