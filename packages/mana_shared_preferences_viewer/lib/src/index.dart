import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_shared_preferences_viewer/src/widgets/shared_preferences_viewer.dart';

import 'icon.dart';

class ManaSharedPreferencesViewer extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) =>
      SharedPreferencesViewer(name: name);

  @override
  String getLocalizedDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'zh':
        return 'Shared Preferences';
      default:
        return 'Shared Preferences';
    }
  }

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_shared_preferences_viewer';
}
