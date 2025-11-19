import 'package:flutter/material.dart';
import 'package:mana/mana.dart';

import 'icon.dart';
import 'widgets/database.dart';

class ManaDatabase extends ManaPluggable {
  @override
  Widget? buildWidget(BuildContext? context) => Database(name: name);

  @override
  ImageProvider<Object> get iconImageProvider => iconImage;

  @override
  String get name => 'mana_database';

  @override
  String getLocalizedDisplayName(Locale locale) {
    if (locale.languageCode == 'zh') {
      return '数据库面板';
    }
    return 'Database';
  }
}
