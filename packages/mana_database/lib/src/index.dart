import 'package:flutter/material.dart';
import 'package:mana/mana.dart';
import 'package:mana_database/src/databases/databases.dart';

import 'icon.dart';
import 'widgets/database.dart';

class ManaDatabase extends ManaPluggable {
  final List<UMEDatabase> databases;

  ManaDatabase({required this.databases});

  @override
  Widget? buildWidget(BuildContext? context) =>
      DatabasePanel(name: name, databases: this.databases);

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
